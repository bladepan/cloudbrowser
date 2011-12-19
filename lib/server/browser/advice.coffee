adviseMethod = (obj, name, func) ->
    originalMethod = obj.prototype[name]
    obj.prototype[name] = () ->
        rv = originalMethod.apply(this, arguments)
        func(this, arguments, rv)
        return rv

adviseProperty = (obj, name, args) ->
    for own type, func of args
        do (type, func) ->
            if type == 'setter'
                oldSetter = obj.prototype.__lookupSetter__(name)
                obj.prototype.__defineSetter__ name, (value) ->
                    rv = oldSetter.apply(this, arguments)
                    func(this, value)
                    return rv
            else if type == 'getter'
                oldGetter = obj.prototype.__lookupGetter__(name)
                obj.prototype.__defineGetter__ name, () ->
                    rv = oldGetter.apply(this, arguments)
                    func(this, rv)
                    return rv

# Adds advice to a number of DOM methods so we can emit events when the DOM
# changes.
exports.addAdvice = (dom, browser) ->
    {html, events} = dom

    # Advice for: HTMLDocument constructor
    #
    # Wrap the HTMLDocument constructor so we can emit an event when one is
    # created.  We need this so we can tag Document nodes.
    do () ->
        oldDoc = html.HTMLDocument
        html.HTMLDocument = () ->
            oldDoc.apply(this, arguments)
            browser.emit 'DocumentCreated',
                target : this
        html.HTMLDocument.prototype = oldDoc.prototype

    # Advice for: Node.insertBefore
    #
    # var insertedNode = parentNode.insertBefore(newNode, referenceNode);
    adviseMethod html.Node, 'insertBefore', (parent, args, rv) ->
        elem = args[0]
        browser.emit 'DOMNodeInserted',
            target : elem
            relatedNode : parent
        # Note: unlike the DOM, we only emit DOMNodeInsertedIntoDocument
        # on the root of a removed subtree, meaning the handler should check
        # to see if it has children.
        if parent._attachedToDocument && elem.nodeType != 11
            browser.emit 'DOMNodeInsertedIntoDocument',
                target : elem
                relatedNode : parent

    # Advice for: Node.removeChild
    #
    # var oldChild = node.removeChild(child);
    adviseMethod html.Node, 'removeChild', (parent, args, rv) ->
        # Note: Unlike DOM, we only emit DOMNodeRemovedFromDocument on the root
        # of the removed subtree.
        if parent._attachedToDocument
            elem = args[0]
            browser.emit 'DOMNodeRemovedFromDocument',
                target : elem
                relatedNode : parent
    
    # Advice for AttrNodeMap.[set|remove]NamedItem
    #
    # This catches changes to node attributes.
    # type : either 'ADDITION' or 'REMOVAL'
    do () ->
        attributeHandler = (type) ->
            return (map, args, rv) ->
                attr = if type == 'ADDITION'
                    args[0]
                else
                    rv
                if !attr then return

                target = map._parentNode
                if target._attachedToDocument
                    browser.emit 'DOMAttrModified',
                        target : target
                        attrName : attr.name
                        newValue : attr.value
                        attrChange : type
        # setNamedItem(node)
        adviseMethod html.AttrNodeMap,
                          'setNamedItem',
                          attributeHandler('ADDITION')
        # attr = removeNamedItem(string)
        adviseMethod html.AttrNodeMap,
                     'removeNamedItem',
                     attributeHandler('REMOVAL')

    # Advice for: HTMLOptionElement.selected property.
    #
    # The client needs to set this as a property, not an attribute, or the
    # selection won't actually be changed.
    adviseProperty html.HTMLOptionElement, 'selected',
        setter : (elem, value) ->
            if elem._attachedToDocument
                browser.emit 'DOMPropertyModified',
                    target   : elem
                    property : 'selected'
                    value    : value

    # Advice for: CharacterData._nodeValue
    #
    # This is the only way to detect changes to the text contained in a node.
    adviseProperty html.CharacterData, '_nodeValue',
        setter : (elem, value) ->
            if elem._parentNode?._attachedToDocument
                browser.emit 'DOMCharacterDataModified',
                    target : elem
                    value  : value

    # Advice for: EventTarget.addEventListener
    #
    # This allows us to know which events need to be listened for on the
    # client.
    # TODO: wrap removeEventListener.
    adviseMethod events.EventTarget, 'addEventListener', (elem, args, rv) ->
        browser.emit 'AddEventListener',
            target      : elem
            type        : args[0]

    # Advice for: all possible attribute event listeners
    #
    # For each type of event that can be listened for on the client, we wrap
    # the corresponding "on" property on each node.
    # TODO: really, this should emit on all event types and shouldn't know
    #       about ClientEvents.
    do () ->
        {ClientEvents} = require('../../shared/event_lists')
        for type of ClientEvents
            do (type) ->
                name = "on#{type}"
                # TODO: remove listener if this is set to something not a function
                html.HTMLElement.prototype.__defineSetter__ name, (func) ->
                    browser.emit 'AddEventListener',
                        target      : this
                        type        : type
                    return this["__#{name}"] = func
                html.HTMLElement.prototype.__defineGetter__ name, () ->
                    return this["__#{name}"]

    # Advice for: HTMLElement.style
    #
    # JSDOM level2/style.js uses the style getter to lazily create the 
    # CSSStyleDeclaration object for the element.  To be able to emit
    # the right instruction in the style object advice, we need to have
    # a pointer to the element that owns the style object, so we create it
    # here.
    adviseProperty html.HTMLElement, 'style',
        getter : (elem, rv) ->
            rv._parentElement = elem

    # This list is from:
    #   http://dev.w3.org/csswg/cssom/#the-cssstyledeclaration-interface
    cssAttrs = [
        'azimuth', 'background', 'backgroundAttachment', 'backgroundColor',
        'backgroundImage', 'backgroundPosition', 'backgroundRepeat', 'border',
        'borderCollapse', 'borderColor', 'borderSpacing', 'borderStyle',
        'borderTop', 'borderRight', 'borderBottom', 'borderLeft',
        'borderTopColor', 'borderRightColor', 'borderBottomColor',
        'borderLeftColor', 'borderTopStyle', 'borderRightStyle',
        'borderBottomStyle', 'borderLeftStyle', 'borderTopWidth',
        'borderRightWidth', 'borderBottomWidth', 'borderLeftWidth',
        'borderWidth', 'bottom', 'captionSide', 'clear', 'clip', 'color',
        'content', 'counterIncrement', 'counterReset', 'cue', 'cueAfter',
        'cueBefore', 'cursor', 'direction', 'display', 'elevation',
        'emptyCells', 'cssFloat', 'font', 'fontFamily', 'fontSize',
        'fontSizeAdjust', 'fontStretch', 'fontStyle', 'fontVariant',
        'fontWeight', 'height', 'left', 'letterSpacing', 'lineHeight',
        'listStyle', 'listStyleImage', 'listStylePosition', 'listStyleType',
        'margin', 'marginTop', 'marginRight', 'marginBottom', 'marginLeft',
        'markerOffset', 'marks', 'maxHeight', 'maxWidth', 'minHeight',
        'minWidth', 'orphans', 'outline', 'outlineColor', 'outlineStyle',
        'outlineWidth', 'overflow', 'padding', 'paddingTop', 'paddingRight',
        'paddingBottom', 'paddingLeft', 'page', 'pageBreakAfter',
        'pageBreakBefore', 'pageBreakInside', 'pause', 'pauseAfter',
        'pauseBefore', 'pitch', 'pitchRange', 'playDuring', 'position',
        'quotes', 'richness', 'right', 'size', 'speak', 'speakHeader',
        'speakNumeral', 'speakPunctuation', 'speechRate', 'stress',
        'tableLayout', 'textAlign', 'textDecoration', 'textIndent',
        'textShadow', 'textTransform', 'top', 'unicodeBidi', 'verticalAlign',
        'visibility', 'voiceFamily', 'volume', 'whiteSpace', 'widows', 'width',
        'wordSpacing', 'zIndex'
    ]

    # Advice for: Element.style.*
    # For each possible style property, add a setter to emit advice.
    do () ->
        proto = html.CSSStyleDeclaration.prototype
        cssAttrs.forEach (attr) ->
            proto.__defineSetter__ attr, (val) ->
                # cssom seems to use some CSSStyleDeclaration objects
                # internally, so we only want to emit instructions if there
                # is a parent element pointer, meaning this CSSStyleDeclaration
                # belongs to an element.
                if this._parentElement && this._parentElement._attachedToDocument
                    browser.emit 'DOMStyleChanged',
                        target : this._parentElement
                        attribute : attr
                        value : val
                return @["_#{attr}"] = val
            proto.__defineGetter__ attr, () ->
                return @["_#{attr}"]
