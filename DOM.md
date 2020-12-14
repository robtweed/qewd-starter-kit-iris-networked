# The QEWD-JSdb DOM Database Model
 
Rob Tweed <rtweed@mgateway.com>  
12 December 2020, M/Gateway Developments Ltd [http://www.mgateway.com](http://www.mgateway.com)  

Twitter: @rtweed

Google Group for discussions, support, advice etc: [http://groups.google.co.uk/group/enterprise-web-developer-community](http://groups.google.co.uk/group/enterprise-web-developer-community)

# About this Document

This document provides background information on the *Persistent XML Document Object Model (DOM)*
 NoSQL database model that is included with QEWD-JSdb.

# About the DOM Database Model

The *DOM* database model is an implementation of the [W3C XML DOM API](https://www.w3.org/TR/2000/REC-DOM-Level-2-Core-20001113/introduction.html).
The implementation is currently somewhere between W3C's Levels 2 and 3 in terms of its standards adherence,
but is sufficiently complete to integrate correctly with the 3rd-party [Node.js XPath module](https://www.npmjs.com/package/xpath)
which is a dependency of the DOM API implementation. 

Unlike the usual XML DOM implementations, it is implemented in the persistent storage provided
by QEWD-JSdb, rather than in-memory.  This means that the documents can be stored as pre-parsed
XML DOMs, and can be searched at any time in-situ within the database using standard XPath queries.

In effect, the QEWD-JSdb *DOM* model provides you with a [Native XML Database](http://www.rpbourret.com/xml/XMLAndDatabases.htm).
One of the most well-known of such products is [MarkLogic](https://en.wikipedia.org/wiki/MarkLogic) which
has evolved from its original XML database roots.

A good resource for learning about the XML DOM APIs, how they work and how they can be used is the
[W3Schools XML DOM Tutorial](https://www.w3schools.com/xml/dom_intro.asp).  The only difference is that
the examples in those tutorials will be working with in-memory XML DOMs, whereas you'll be using
DOMs in database storage.


Before proceeding it is recommended that you first read and complete the [basic QEWD-JSdb tutorial](./REPL.md).  This will ensure you 
understand what's going on in the QEWD-JSdb and why!


# Source Code for the DOM APIs

Like all the QEWD-JSdb APIs, they are written in JavaScript and are built on top of the
standard QEWD-JSdb APIs.  They are all Open Source APIs, and
you are free to inspect and use the code as you wish, in accordance with the Apache 2 license under
which they are made available.

Find the [DOM source code here](https://github.com/robtweed/ewd-document-store/tree/master/lib/proto/dom).


# Enabling Use of the DOM APIs

You can create and maintain a *DOM* at any QEWD-JSdb Document Node Object.

Having instantiated the Document Object Node object, you must enable its use of the *DOM* APIs.
For example, from within a QEWD-Up back-end message handler module:

        doc = this.documentStore.use('jsdbDom', 'demo')
        doc.enable_dom()

or when using the *jsdb_shell* REPL module:

        doc = jsdb.use('jsdbDom', 'demo')
        doc.enable_dom()

The QEWD-JSdb Document Node object will be augmented with a *dom* property object, 
via which you can invoke the *DOM* APIs, eg:


        documentNode = doc.dom.createDocument();

The DOM APis allow you to:

- build and manipulate a DOM from scratch, entirely using the APIs
- ingest the text of an XML document and convert it to a DOM, after which it can be manipulated using
the DOM APIs
- output a DOM as XML text which, for example, can then be saved as a file

The DOM APIs can also be used with JSON.  For example, you can:

- ingest JSON and represent it as a DOM, after which it can be manipulated using
the DOM APIs
- output a DOM as a corresponding JSON text which can then be saved as a file.



# Building a DOM Programmatically

You can build a DOM, representing an XML Document, completly from scratch, using the DOM APIs.
In this tutorial, I'll show you how.

## Getting Started

You can do this in a back-end QEWD REST API method or interactive message handler, but
you can also do it interactively using the *jsdb_shell* Module, which is what I'll describe here.

[Start the Node.js REPL and load the *jsdb_shell* Module](./REPL.md#getting-started). Then
instantiate a QEWD-JSDB *Document Node Object* for a Document (ie IRIS Global) named *jsdbDom*,
and a subscript of *demo*:


        var doc = jsdb.use('jsdbDom', 'demo')

Next, enable it to behave as a *DOM*:

        doc.enable_dom()

At this point, if you look in your IRIS system, you won't see a Global named *^jsdbDom* yet.

## The documentNode

The first step is to create the (initially empty) DOM Document:

        var documentNode = doc.dom.createDocument()


If you take a look in your IRIS system, you'll see that the following Global nodes have
been created:

        USER> zw ^jsdbDom
        
        ^jsdbDom("demo","documentNode")=1
        ^jsdbDom("demo","index","by_nodeName",9,"#document",1)=""
        ^jsdbDom("demo","index","by_nodeType",9,1)=""
        ^jsdbDom("demo","nextNodeNo")=1
        ^jsdbDom("demo","node",1,"nodeName")="#document"
        ^jsdbDom("demo","node",1,"nodeNo")=1


Every DOM has a notional top-level node, known as the *documentNode*, under which everything
else is attached.  It won't appear in the actual XML text: you can try this
by displaying the output from the *output()* DOM API method:

        console.log(doc.dom.output())

You won't get anything displayed.  However, we can interrogate the DOM to see what it
currently contains.

The *createDocument()* method returned a pointer to the *documentNode*.  However, 
having created a new DOM Document, we can also access its *documentNode* using:

        var dnode = doc.dom.documentNode


All DOM Nodes have several mandatory properties, in particular *nodeType* and *nodeName*.

Let's see what they are for our *documentNode*:

        console.log(dnode.nodeType)
        // 9

        console.log(dnode.nodeName)
        // #document

A DOM can, of course, only have one *documentNode*.

If you look in the IRIS Global that represents our DOM, you'll see how and where these
properties are stored.

## Add an XML Tag

There are two ways to add an XML Tag to our DOM:

- the low-level way, using the primitive DOM API methods
- the high-level way, using a single method that, behind the scenes, uses the appropriate primitive
DOM API methods to create a tag and attributes and attach it to the DOM

### Low-Level APIs

First let's look at the low-level way.  You add a tag by:

- creating an Element node (*createElement()*)
- optionally, adding attribute name/values to the Element (*setAttribute()*)
- optionally adding text content to the Element (*textContent()*)
- append the Element to an existing Node in the DOM (*appendChild()* or *insertBefore()*)

#### *createElement()*

So, first create an XML Element Node named *myTag*.  This will be the
equivalent of creating:

        <myTag />

Type this:

        var el = doc.dom.createElement('myTag')

If you look in IRIS you'll see what's been created:

        USER> zw ^jsdbDom
        
        ^jsdbDom("demo","documentNode")=1
        ^jsdbDom("demo","index","by_nodeName",1,"myTag",2)=""
        ^jsdbDom("demo","index","by_nodeName",9,"#document",1)=""
        ^jsdbDom("demo","index","by_nodeType",1,2)=""
        ^jsdbDom("demo","index","by_nodeType",9,1)=""
        ^jsdbDom("demo","nextNodeNo")=2
        ^jsdbDom("demo","node",1,"nodeName")="#document"
        ^jsdbDom("demo","node",1,"nodeNo")=1
        ^jsdbDom("demo","node",1,"nodeType")=9
        ^jsdbDom("demo","node",2,"nodeName")="myTag"
        ^jsdbDom("demo","node",2,"nodeNo")=2
        ^jsdbDom("demo","node",2,"nodeType")=1

You can see that a second Node has been added, representing the Element.

Yet, if you output the XML:

        console.log(doc.dom.output())

you'll not see anything.  That's because, whilst the Element has been created
within the DOM, it hasn't actually been attached to one of its nodes.  This is an
important feature when working with the DOM: nodes can exist within it, yet can be
unattached to anything.

We can check its properties:

- Element nodes have a *nodeType* of 1:

        console.log(el.nodeType)
        // 1

- Its *nodeName* is the actual tag name:

        console.log(el.nodeName)
        // myTag

- Element nodes have another property: *tagName*, which, unsurprisingly, is the
same as the *nodeName* property:

        console.log(el.tagName)
        // myTag


#### *appendChild()*

You don't need to attach the Element until you've added any attributes and text content,
but the order of these steps doesn't really matter.  if we attach the Element to the DOM now,
the benefit is we'll be able to view the effect of all the subsequent steps by using
the *output()* method.

Currently the only node that exists is the *documentNode*, so that's where we attach
our Element:

      var elx = dnode.appendChild(el)

Now try this:

        console.log(doc.dom.output())

        // <myTag />

There we go! Our XML document has begun to exist!

Only one Element node can be attached to the DOM's *documentNode*, and it's known
as the *documentElement* - the top-most tag in an XML Document.  
You can access a DOM's *documentElement* using:

      var docEl = doc.dom.documentElement

All other tags in an XML document are descendents of the *documentElement*.


#### Add Another Tag

We can now add another tag to the DOM and append it as a child of the *documentElement*:

        var el2 = doc.dom.createElement('myChildTag')
        el.appendChild(el2)

        // alternatively we could have used
        //  docEl.appendChild(el2)

        console.log(doc.dom.output())

        // <myTag><myChildTag /></myTag>


We can tidy up the output - instead of streaming the XML, we can specify a number of indents, eg let's
say 2 indents:


        console.log(doc.dom.output(2))

which will now output:


        <myTag>
          <myChildTag />
        </myTag>

Building out a basic DOM is no more than these steps: creating nodes and appending them
to a parent tag, eg we could continue with:

        var el3 = doc.dom.createElement('mySecondChildTag')
        elx = el.appendChild(el3)
        var el4 = doc.dom.createElement('myGrandChildTag')
        elx = el3.appendChild(el4)
        console.log(doc.dom.output(2))

which will now output:

        <myTag>
          <myChildTag />
          <mySecondChildTag>
            <myGrandChildTag />
          </mySecondChildTag>
        </myTag>


#### *setAttribute()*

An XML tag can optionally have one or more attributes.  Let's add one to one of 
our Elements now.  We use the Element Node's *setAttribute()* method:

        var attr1 = el2.setAttribute("foo","bar")

and see what's happened:

        console.log(doc.dom.output())

        <myTag>
          <myChildTag foo="bar" />
          <mySecondChildTag>
            <myGrandChildTag />
          </mySecondChildTag>
        </myTag>

Let's add another two attributes:


        var attr2 = el2.setAttribute("hello","world")
        var attr3 = el2.setAttribute("id","firstTag")

Let's check what those two commands did:

        console.log(doc.dom.output())

        <myTag>
          <myChildTag foo="bar" hello="world" id="firstTag" />
          <mySecondChildTag>
            <myGrandChildTag />
          </mySecondChildTag>
        </myTag>

#### *textContent*

An XML Tag can also optionally have text content, ie between its opening
and closing Tag.  Let's add text to the *myGrandChild* tag:


        el4.textContent = "Some text content"
        console.log(doc.dom.output(2));

        <myTag>
          <myChildTag foo="bar" hello="world" id="firstTag" />
          <mySecondChildTag>
            <myGrandChildTag>
              Some text content
            </myGrandChildTag>
          </mySecondChildTag>
        </myTag>


So these steps are how to create XML Tags along with their attributes and text content


### High-Level Method for Tag Creation

Every Element has an additional method: *appendElement()* which combines all the steps
covered above.  *appendElement()* takes a single argument which is an object defining:

- tagName (mandatory)
- attribute name/value pairs (optional)
- text content (optional)

So let's repeat the previous steps, but using *appendElement()* instead.

First, clear down your previous DOM:

        doc.delete()

Then do the following:

        
        var documentNode = doc.dom.createDocument()
        var el1 = documentNode.appendElement({tagName: 'myTag'})
        var el2 = el1.appendElement({
          tagName: 'myChildTag',
          attributes: {
            foo: 'bar',
            hello: 'world',
            id: 'firstTag'
          }
        })
        var el3 = el1.appendElement({tagName: 'mySecondChildTag'})
        var el4 = el3.appendElement({
          tagName: 'myGrandChildTag',
          text: 'Some text content'
        })

Then see the results:

        console.log(doc.dom.output(2));

        <myTag>
          <myChildTag foo="bar" hello="world" id="firstTag" />
          <mySecondChildTag>
            <myGrandChildTag>
              Some text content
            </myGrandChildTag>
          </mySecondChildTag>
        </myTag>

So we've created the very same XML Document, but much more simply!


## The Persistent DOM

As you've seen when you looked in IRIS, the QEWD-JSdb DOM is persistent, being stored
in a Global: in our case it's the *^jsdbDom* Global.

So this take a look at what this means in practice.

Exit from the Node.js REPL that you've been using: type *CTRL & C* twice.

So you've now disconnected from IRIS.

Now restart the REPL and re-connect:

        node

        > var jsdb = require('./jsdb_shell')


Do this again:

        var doc = jsdb.use('jsdbDom', 'demo')
        doc.enable_dom()

And now see what happens when you do this:

        console.log(doc.dom.output(2));

Yes, your DOM is still there!


## Navigating the DOM

The DOM APIs allow you to navigate within the DOM to access individual Tags, Attributes
and Text Content.  You can then edit or remove them, or add further content.

We've already seen how you can access the *documentNode* and *documentElement*.

For example:

        console.log(doc.dom.documentElement.tagName)

        myTag


### Navigating Between Adjacent Elements

Every Element Node has a number of properties to allow you to navigate to other adjacent ones:

- firstChild
- lastChild
- nextSibling
- previousSibling
- parentNode

For example:

        var el1 = doc.dom.documentElement
        console.log(el1.firstChild.tagName)

which will return:

        myChildTag

Next try:

        console.log(el1.lastChild.tagName)

which returns:

        mySecondChildTag


Alternatively we could do this:

        var el2 = el1.firstChild
        console.log(el2.nextSibling.tagName)

and again we get:

        mySecondChildTag

Or navigate in the other direction:

        var el2 = el1.lastChild
        console.log(el2.previousSibling.tagName)

which gives us:

        myChildTag

Note the way that the properties and methods can be chained, for example:

        console.log(el1.firstChild.nextSibling.firstChild.tagName)

which returns:

        myGrandChildTag


We can also navigate up the DOM's hierarchy by using the *parentNode* property.
Start here:

        var gc = el1.firstChild.nextSibling.firstChild
        console.log(gc.tagName)

Now go up to its parent:

        console.log(gc.parentNode.tagName)

and up another level:

        console.log(gc.parentNode.parentNode.tagName)

That's the top-most XML Element.  What happens if we try to go up another level?

        console.log(gc.parentNode.parentNode.parentNode.tagName)

That returns undefined.  Try this though:

        console.log(gc.parentNode.parentNode.parentNode.nodeName)

As you can see, you get:

        #document

because you've reached the DOM's *documentNode*

Try going any higher and, not surprisingly, you'll get errors.


### *getElementsByTagName()*

Clearly, the properties above are useful for moving around within adjacent Elements, but
it's a laborious way to get to a particular node that you might want to access.

So the DOM provides other methods.  For example, we could get straight to that *myGrandChildTag*
Element like this:

        var nl = doc.dom.getElementsByTagName('myGrandChildTag')

What's returned (ie *nl*) is a somewhat unusual data structure, unique to the DOM and
known as a NodeList.  It behaves like an Array, but is actually a *live* object - reflecting
the actual content of the DOM if it is subsequently changed.  For those interested in how
this is implemented in QEWD-JSdb, it uses a JavaScript Proxy Object whose properties and
methods directly access the IRIS database when they're invoked, so they always return what's
actually in the DOM at the time they're invoked.

Try this:

        nl.length

        1

So it found 1 Element Node with a *tagName* of *myGrandChildTag*.

To access the Element Node, use nl[0] as if it's an Array, eg:

        nl[0].tagName

        myGrandChildTag


So we could have done this:

        var gc = doc.dom.getElementsByTagName('myGrandChildTag')[0]

*gc* is now the Element Node object we want


### *getElementById()*

There's another way to navigate the DOM to specific Elements, which is available
for any Tags that have an *id* Attribute.  The *id* is deemed to be a special attribute
name, and each *id* value within a DOM is unique.  The *id* Attributes are specifically
indexed, so they provide a rapid route to get to a particular Element.

If you remember, we added an *id* Attribute to one of our Tags:


          <myChildTag foo="bar" hello="world" id="firstTag" />


We can get directly to this Element as follows:

        var mc = doc.dom.getElementById('firstTag')

Because *id*s are unique, the *getElementById()* method returns the matching Element Node Object.
If the specified *id* doesn't exist, it returns a *null*.






... To be continued
