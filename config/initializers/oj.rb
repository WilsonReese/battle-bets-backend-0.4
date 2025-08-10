require "oj"

Oj.optimize_rails # hooks Oj into ActiveSupport JSON encoding

Oj.default_options = {
  mode: :rails,         # Rails-compatible
  time_format: :xmlschema,
  use_to_json: true,    # still respect your models' to_json/as_json
  allow_nan: false,     # keep JSON strictly valid
  escape_html: false    # set true only if you embed JSON in HTML
}