API debugging with Between
==========================

Introduction
------------

HTTP isn't just a protocol for the web, it's become the preferred protocol for application APIs. Between is a tool for debugging applications that use web APIs. It acts as a proxy between your application and the remote application, tracking all communication between them in real-time and presenting the information to the user.

Getting Started
---------------

## Interceptor Subdomain

Interceptor Subdomains are the easiest way to to get started with Between. They can be created instantly and dropped-in to your application configuration in place of existing strings. Your application will act the same, but all communication made to the interceptor subdomain will be visible on Between.

### Determine hostname of API

Between can be used to gain insight into the communication between your computer or development server and an API server. To do this, you must first determine the hostname of the remote API server. This will be provided by the API documentation and is simply the domain or subdomain portion of the URLs that requests are made to. For example, in the case of the Faceboook Graph API, to access the graph object with a given ID you make a request to `http://graph.facebook.com/[ID]`. The hostname for the Facebook Graph API is `graph.facebook.com`, and that's what you would provide to Between.

### Generate an interceptor subdomain

After logging in to Between, click "new interceptor subdomain". Provide the hostname of the API and, if necessary, the port. Click "ok". Copy the hostname returned by between.

### Insert into your code

Now that you have the interceptor subdomain, add it to your configuration in place of the original API hostname. This will depend on how your code is set up, but a common practice is for the API enpoint to be stored in a constant in a configuration file or API wrapper class. If the hostname appears multiple times throughout the code, this would be a good time to clean up the code by making it a single configurable parameter.

For example, if your code looks like this:

    FACEBOOK_GRAPH_API_ENDPOINT = "http://graph.facebook.com/"

You would replace it with

    FACEBOOK_GRAPH_API_ENDPOINT = "http://[interceptor subdomain]/"

If you are using a third-party or vendor-provided library for accessing the API, it may not provide an interface for changing the API hostname. In this case you will have to dig into the library code and change it yourself, or else use the HTTP proxy method described below.

### Webhooks

The interceptor instructions above describe intercepting outgoing communication with a remote server, but it can just as easily be used to interact with incoming communication. Simply create an interceptor with the hostname of your server. The interceptor subdomain can be given to a remote server where you would otherwise provide your hostname. For example, this could be used to debug webhooks.

## HTTP Proxy



