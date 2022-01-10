module Setup
  class Snippet
    include SharedEditable
    include NamespaceNamed

    TYPES = {
      'Auto detect': :auto,
      'Plain text': :text,
      'APL': :apl,
      'ASCIIArmor': :asciiarmor,
      'ASN.1': :'asn.1',
      'Asterisk dialplan': :asterisk,
      'Brainfuck': :brainfuck,
      'C': :c,
      'C++': :cpp,
      'C#': :csharp,
      'Clojure': :clojure,
      'CMake': :cmake,
      'Cobol': :cobol,
      'CoffeeScript': :coffeescript,
      'Cold Fusion': :cfm,
      'Crystal': :crystal,
      'CSS': :css,
      'CSV': :csv,
      'Cypher': :cypher,
      'D': :d,
      'Dart': :dart,
      'Diff': :diff,
      'Docker': :dockerfile,
      'DTD': :dtd,
      'Dylan': :dylan,
      'EBNF': :ebnf,
      'ECL': :ecl,
      'Eiffel': :eiffel,
      'Elm': :elm,
      'Erlang': :erlang,
      'Factor': :factor,
      'Forth': :forth,
      'Fortran': :fortran,
      'F#': :fsharp,
      'Gas': :gas,
      'Gherkin': :gherkin,
      'Go': :go,
      'Groovy': :groovy,
      'HAML': :haml,
      'Handlebars': :handlebars,
      'Haskell': :haskell,
      'Haxe': :haxe,
      'HTML': :htmlmixed,
      'HTTP': :http,
      'IDL': :idl,
      'Java': :java,
      'JavaScript': :javascript,
      'JSON': :javascript,
      'Jinja2': :jinja2,
      'Julia': :julia,
      'Kotlin': :kotlin,
      'LaTeX': :latex,
      'LiveScript': :livescript,
      'Lisp': :commonlisp,
      'Lua': :lua,
      'Markdown': :gfm,
      'Mathematica': :mathematica,
      'mIRC': :mirc,
      'Modelica': :modelica,
      'MUMPS': :mumps,
      'Nginx': :nginx,
      'NTriples': :ntriples,
      'Objective-C': :objc,
      'OCaml': :ocaml,
      'Octave': :octave,
      'Pascal': :pascal,
      'PEG.js': :pegjs,
      'Perl': :perl,
      'PHP': :php,
      'Pig Latin': :pig,
      'Post': :post,
      'Properties': :properties,
      'Puppet': :puppet,
      'Python': :python,
      'Q': :q,
      'R': :r,
      'reStructuredText': :rst,
      'RPM': :rpm,
      'Ruby': :ruby,
      'Rust': :rust,
      'Sass': :sass,
      'Scala': :scala,
      'Scheme': :scheme,
      'Shell': :shell,
      'Sieve': :sieve,
      'Slim': :slim,
      'SmallTalk': :smalltalk,
      'Smarty': :smarty,
      'Solr': :solr,
      'Soy': :soy,
      'SPARQL': :sparql,
      'SQL': :sql,
      'Squirrel': :squirrel,
      'sTex': :stex,
      'Swift': :swift,
      'TCL': :tcl,
      'Textile': :textile,
      'Tiddlywiki': :tiddlywiki,
      'Tiki wiki': :tiki,
      'TOML': :toml,
      'Tornado': :tornado,
      'Troff': :troff,
      'TTCN': :ttcn,
      'Turtle': :turtle,
      'Twig': :twig,
      'VB.net': :vb,
      'VBScript': :vbscript,
      'Velocity': :velocity,
      'Verilog': :verilog,
      'VHDL': :vhdl,
      'XML': :xml,
      'XQuery': :xquery,
      'Z80': :z80
    }.freeze

    build_in_data_type.referenced_by(:namespace, :name).and(
      properties: {
        type: {
          enum: TYPES.values.map(&:to_s),
          enumNames: TYPES.keys.map(&:to_s),
          default: ''
        }
      }
    )

    field :description, type: String
    field :type, type: StringifiedSymbol, default: :auto
    field :code, type: String, default: ''

    # TODO: has_and_belongs_to_many :tags, class_name: Setup::Tag.to_s, inverse_of: nil

    validates_presence_of :name, :code
    validates_inclusion_of :type, in: ->(snippet) { snippet.type_enum.values }

    before_validation do
      @snippet_code_owner.configure_snippet if @snippet_code_owner
      self.name = name.strip
    end

    before_save do
      if type == :auto
        language = ::LanguageSniffer.detect(name, content: code).language
        self.type =
          if language && (language = type_enum[language.name.to_sym])
            language
          else
            'text'
          end
      end
      abort_if_has_errors
    end

    after_save :clean_code_cache

    def clean_code_cache
      Capataz::Cache.clean(code_key)
    end

    def code_key
      prefix =
        case origin
        when :default
          Tenant.current&.id
        when :owner
          Tenant.current&.owner&.id
        else
          origin
        end
      "#{prefix}##{id}"
    end

    def type_enum
      TYPES
    end

  end
end
