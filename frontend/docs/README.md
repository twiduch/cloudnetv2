#API DOCS

We're using [Swagger UI](https://github.com/swagger-api/swagger-ui) to automatically generate the API docuementation.

The grape-swagger gem autogenerates a JSON endpoint (piggybacking off the cloud.net API domain at `/swagger_doc`).
Swagger UI itself is just a static HTML and JS site that queries the JSON endpoint generated from grape-swagger.

To save adding the whole of the Swagger UI static site we simply symlink to the npm-installed files under `node_modules`.
But we need to edit the index.hml file, which means that that can't be symlinked. Therefore, bear in mind that if you
need to update the index.html here from a future version of Swagger UI, then you need to make sure all the assets in
`<head>` point to the `/dist` folder.
