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
