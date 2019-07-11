# koha-plugin-ill-avail-unpaywall

This plugin provides ILL availability searching for the Unpaywall API.

## Configuration

When the plugin is installed, the configuration screen requires you to specify an email address to be passed with all API requests. This is a requirement of the [Unpaywall API](https://unpaywall.org/products/api)

**Note**: Currently the core Koha support for ILL availability searching is not in master. Therefore, until it is, it is necessary to apply [Bug 23173](https://bugs.koha-community.org/bugzilla3/show_bug.cgi?id=23173)
to your Koha instance in order to use this plugin.

## How to use the plugin

When creating an ILL request using the FreeForm plugin, once the item metadata is entered and the form is submitted, if the request contains metadata that can be searched by Unpaywall (DOI is the only supported metadata property), the user will be taken to an "Availability" page.

The Unpaywall API will be searched and results displayed.
The user can then click on the result titles to view them. If they find the item they were requesting then the request should be abandoned by the user. If not, the user can continue with the request as normal.

## Developers

This plugin is intended to be a "reference" example of how to create an availability plugin. The Unpaywall API is extremely simple and therefore doesn't get in the way of demonstrating the requirements for a plugin. The following assumes familiarity with how Koha plugins are developed. If you need more information on this, the [Kitchen Sink](https://github.com/bywatersolutions/koha-plugin-kitchen-sink) should give you a leg up.

The code is reasonably well commented, however here are some highlights:

`ill_availability_services`
This method is required. It receives all the metadata pertaining to the item being requested. Metadata should conform to the property names [specified here](https://github.com/PTFS-Europe/koha-ill-freeform/blob/master/Base.pm#L890-L924) The job of this method is to determine if this plugin can service the requested metadata, i.e. does the service being represented support the supplied metadata, is the plugin correctly configured? If not, the method should return `0`. If it can, the method should return a hashref containing:
* id - A unique ID for this service
* plugin - The name of this plugin, suitable for display
* endpoint - The URL of the API route being provided by this plugin to allow searching of the service. This endpoint is handled by the Api.pm module in your plugin.
* datatablesConfig - Any configuration you may wish to pass to the datatable being used to display your plugin's results, for example, if you wish to not display pagination, this should be specified here. Note: true / false should be quoted.

`Api.pm`
This is the module that handles the endpoint specified in `ill_availability_services`. It works in exactly the same way as any other Koha API endpoint. The JSON object it returns should contain a `search_results` object which is an array of results. Each result can contain the properties `source`, `title`, `author`, `isbn`, `issn`, `date` & `url`.
