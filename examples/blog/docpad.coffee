
module.exports =

    # The data generated by minicms is just like any other content
    # So we do like any other docpad project, we add template helpers to retrieve it
    templateData:

        getIndex: ->
            @getCollection('html').findOne(url: '/')?.toJSON()

        getArticles: ->
            @getCollection('html').findAllLive(type: 'article').sortArray(date:-1)

        getLinks: ->
            @getCollection('html').findAllLive(type: 'link').sortArray(name:1)

    plugins:

        # This contains all the configuration of minicms, used for the admin panel of our blog
        # It allows you to define lists, forms and how to generate the final content
        minicms:

            #prefix:
            #    url:    'cms'     # Access the admin panel through '/cms' by default
            #    meta:   'cms'     # Store form data of each content into a 'cms' field by default (inside metadata)

            # Secret, required by signed cookie session
            secret: 'keyboard cat blog' 

            # Implement the logic you want for authentication
            auth: (login, password, callback) ->
                if login is 'admin' and password is 'password'
                    callback null, true
                else
                    callback "Invalid login or password.", false

            # List all the content that is managed by the plugin
            models: [
                # Example of a content that is unique and only has 1 entry
                name:   ['Configuration', 'Configuration'] # First is singular name, second is plural. Here we use the same because we never have multiple "Configurations"
                unique: true # Make this model "unique", that means there can only be 1 entry, not more, not less
                form:
                    url:    "/index" # Save configuration meta in index file
                    ext:    'html.md' # With a ".html.md" extension

                    # Set the metadata template of the file
                    # Each function that we put in the metadata will be called and the result will be used
                    # The context (this, @) contains the @docpad instance, a @slugify function and all the properties of the current model
                    meta:
                        title:      -> @title 
                        layout:     'home'
                        about:      -> @about

                    # The content follows the metadata. For this file, it is in markdown (because we are making a html.md file)
                    content:    -> @title

                    # For each model, we can create a form with several components that will allow the user to input data
                    components: [
                        # A 'title' field with a text input component (notice that we use this title field in the metadata template, above)
                        field:      'title'
                        label:      'Website Title' # The label is what will appear as field name in the form for the admin panel
                        type:       'text'
                    ,
                        # Another text input component to type the Author of the website (this one is still stored in the cms: key of the meta, but we don't really use it for now. Maybe later?)
                        field:      'author'
                        label:      'Website Author'
                        type:       'text'
                    ,
                        # An 'about' field using a plain textarea component
                        field:      'about'
                        label:      'About me'
                        type:       'textarea'
                        height:     100
                    ,
                        # We can choose a 'category' with a choice component.
                        field:      'category'
                        label:      'Category'
                        type:       'choice'
                        expanded:   true # The component will be "expanded" using html radio inputs

                        # The data: option returns an array of available categories.
                        # For this example, it is hardcoded but you can make your own logic using @docpad collections
                        data:       ->  ['Sport', 'News']
                    ,
                        # We add a 'sub-category' field that depends on the 'category' field
                        field:      'subCategory'
                        deps:       ['category'] # This field will update when the category field changes value
                        label:      'Sub-category'
                        type:       'choice'

                        # Here, we use the @category value to decide which sub-categories are available
                        # It will be called each time the field reloads
                        data:       ->
                                        if @category is 'Sport'
                                            return ['Footbal', 'Tennis', 'Handball', 'Swimming']
                                        else if @category is 'News'
                                            return ['Technology', 'Finance', 'Gossip']
                                        else # No category selected, then no sub-category available
                                            return []
                    ,
                        # Allow the user to change the blog logo by uploading an image
                        field:      'logo'
                        label:      'Website Logo'
                        type:       'file'
                        use:        'standard' # There can be multiple image profiles, here we define the one that will be displayed inside the form
                        optional:   true # We can make a field optional
                        images: # Image profiles
                            # For this field, we only make 1 profile called 'standard' that will resize the image to fit in a 220x220 rectangle.
                            standard:
                                # You can hardcode an extension (png, jpg, gif), or use the @ext value to dynamically generate the right type.
                                # Also works with animated gifs (but a bit experimental)
                                url:        -> "/logo.#{@ext}" # The url to create for the image
                                width:      220 # The maximum width of the image
                                height:     220 # The maximum height of the image
                    ,
                        # An example of rich text field 'wysiwyg' component
                        # The resulting value will be valid html
                        field:      'wysiwygExample'
                        label:      'Wysiwyg example'
                        type:       'wysiwyg'
                        height:     450 # Optional, set the height of the field inside the form
                    ,
                        # An example of 'markdown' component, so you can choose your philosophy: wysiwyg or markdown
                        field:      'markdownExample'
                        label:      'Markdown example'
                        type:       'markdown'
                        height:     450 # Optional, set the height of the field inside the form
                    ]
            ,
                # Example of a model that can have several entries.
                # We are making a blog, so we need articles!
                name:   ['Article', 'Articles'] # First is singular form, second is plural form. Note that urls inside admin panel will be generated by slugifying those names.
                list:
                    # Because this model can have several entries, we need a list page.
                    # Here is the configuration of it
                    # A list is showing several 'fields' of each entries inside a table layout
                    fields: [
                        name:   'Title' # Name of the 'field' in the table
                        value:  -> @title # The function will be called and the value will be used for display. Inside the function, you have access to all the entry's meta
                    ,
                        name:   'Image'
                        # If you want to display html that won't be escaped, use 'html' instead of 'value'
                        html:   ->
                            if @image?
                                return '<div style="height:32px"><img src="'+@image.square.url+'" style="width:32px;height:32px" alt="image" /></div>'
                            else
                                return '<div style="height:32px">&nbsp; - &nbsp;</div>'
                    ,
                        name:   'Tags'
                        html:   ->
                            if @tags instanceof Array
                                return @tags.join(', ')
                            else
                                return ''
                    ]
                    # You can add filters to you list to make browsing easier
                    filters: [
                        name:   'Tag' # Filter by tag
                        # The data function returns all the available values to use on the filter
                        # Here, we are walking through the articles to find all tags
                        data:   ->
                                    tags = []
                                    filter = type: 'article'
                                    for item in @docpad.getCollection('html').findAll(filter).models
                                        itemTags = item.get('tags')
                                        if itemTags instanceof Array
                                            for tag in itemTags
                                                if not (tag in tags)
                                                    tags.push tag
                                    return tags
                    ,
                        # A custom filter to choose articles with image or articles without image only
                        name:   'Kind'
                        data:   ->  ['With Image', 'Textual']
                    ]
                    # The list's data function is returning all the entries of the list.
                    # It is in charge to take in account the filters values
                    # When a filter changes, this function is called again to update the list
                    # The result of this function can be a Docpad Collection or a JSON-like array
                    data:   ->
                                filter = type: 'article'

                                # Filter by kind (with image or not)
                                if @kind is 'with-image'
                                    filter.image = $ne: null
                                else if @kind is 'textual'
                                    filter.image = null

                                collection = @docpad.getCollection('html').findAll(filter)

                                if @tag?
                                    # Filter by tags
                                    finalModels = []
                                    if collection.models instanceof Array
                                        for model in collection.models
                                            tags = model.get('tags')
                                            for tag in tags
                                                if @slugify(tag) is @tag
                                                    finalModels.push model.toJSON()
                                                    break
                                    return finalModels
                                else
                                    return collection

                form:
                    # As with the configuration model, we need a form to add/edit articles
                    url:    -> "/blog/#{@slugify @title}" # Each article's url. We slugify the title to generate the url
                    ext:    'html.md'
                    meta:
                        title:      -> @title
                        type:       'article'
                        layout:     'article'
                        image:      -> @image
                        tags:       -> if @tags instanceof Array then @tags else []
                        date:       -> new Date(@date)
                    content:    -> @content
                    components: [
                        field:      'title'
                        type:       'text'
                    ,
                        # A 'date' field with a datetime picker
                        field:      'date'
                        type:       'date'
                        # You can remove the hours by adding time: false
                        #time:       false
                    ,
                        # Choose the tags of your article
                        field:      'tags'
                        type:       'tags'
                        data:       ->
                                        # The data is used for autocompletion
                                        tags = []
                                        for item in @docpad.getCollection('html').findAll().models
                                            itemTags = item.get('tags')
                                            if itemTags instanceof Array
                                                for tag in itemTags
                                                    if not (tag in tags)
                                                        tags.push tag
                                        return tags
                    ,
                        field:      'content'
                        type:       'markdown'
                        # You can add your custom validator on any field
                        # Well, this is actually useless here because the default validator is doing the same check,
                        # but feel free to check more things for your own needs.
                        validate:   (val) -> typeof(val) is 'string' and val.length > 0
                        # You can also add your custom sanitizer that will be called before saving the content
                        sanitize:   (val) -> return val?.trim()
                    ,
                        field:      'image'
                        type:       'file'
                        use:        'thumbnail'
                        optional:   true
                        images:
                            # This time we have 3 image profiles
                            # Each of them will be generated from the original picture
                            # Notice they all have a different url
                            standard:
                                url:       -> "/blog/#{@slugify @title}.#{@ext}"
                                width:      498
                                height:     9999999
                            thumbnail:
                                url:       -> "/blog/#{@slugify @title}.tn.#{@ext}"
                                width:      9999999
                                height:     128
                            square:
                                url:       -> "/blog/#{@slugify @title}.sq.#{@ext}"
                                width:      32
                                height:     32
                                crop:       true # With this option, the image will be cropped in order to have the exact 32x32 size
                    ]
            ,
                # Another model to add links on the sidebar of the blog
                # Nothing more than the articles model
                name:   ['Link', 'Links']
                list:
                    fields: [
                        name:   'Name'
                        value:  -> @title
                    ,
                        name:   'URL'
                        html:   -> @href
                    ]
                    data:   ->
                                filter = type: 'link'
                                return @docpad.getCollection('html').findAll(filter)

                form:
                    url:    -> "/link/#{@slugify @name}"
                    ext:    'html.md'
                    meta:
                        title:      -> @name
                        type:       'link'
                        layout:     'link'
                        href:       -> @url
                    content:    -> @url
                    components: [
                        field:      'name'
                        type:       'text'
                    ,
                        field:      'url'
                        label:      'URL'
                        type:       'text'
                    ]
            ]



