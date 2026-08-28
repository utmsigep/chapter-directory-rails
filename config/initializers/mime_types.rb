# Be sure to restart your server when you modify this file.

# Rack doesn't know the .mjs extension by default, so static ES module
# files (public/maplibre/*.mjs) get served as text/plain, which browsers
# refuse to execute as a module Worker/script.
Rack::Mime::MIME_TYPES['.mjs'] = 'text/javascript'
