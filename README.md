# DSLimple

![After DSLimple](http://zeny.io/blog/2016/02/14/dslimple-v1/after-dslimple.png)

__DSLimple__ is a tool to manage [DNSimple](https://dnsimple.com/).

It defines the state of DNSimple using DSL, and updates DNSimple according to DSL.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'dslimple'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install dslimple

## Usage

```shell
export DLSIMPLE_EMAIL="..."
export DLSIMPLE_API_TOKEN="..."
dslimple export -f Domainfile
vi Domainfile
dslimple apply --dry-run -f Domainfile
dslimple apply --yes -f Domainfile
```

### Help

```
$ dslimple help
Commands:
  dslimple apply           # Apply domain specifications
  dslimple export          # Export domain specifications
  dslimple help [COMMAND]  # Describe available commands or one specific command

Options:
  -e, [--email=EMAIL]                 # Your E-Mail address
  -t, [--api-token=API_TOKEN]         # Your API token
  -dt, [--domain-token=DOMAIN_TOKEN]  # Your Domain API token
      [--sandbox], [--no-sandbox]     # Use sandbox API(at sandbox.dnsimple.com)
                                      # Default: true
      [--debug], [--no-debug]
```

#### help apply

```
$ dslimple help apply
Usage:
  dslimple apply

Options:
  -o, [--only=one two three]                 # Specify domains for apply
  -d, [--dry-run], [--no-dry-run]
  -f, [--file=FILE]                          # Source Domainfile path
                                             # Default: Domainfile
      [--addition], [--no-addition]          # Add specified records
                                             # Default: true
      [--modification], [--no-modification]  # Modify specified records
                                             # Default: true
      [--deletion], [--no-deletion]          # Delete unspecified records
                                             # Default: true
  -y, [--yes], [--no-yes]                    # Do not confirm on before apply
  -e, [--email=EMAIL]                        # Your E-Mail address
  -t, [--api-token=API_TOKEN]                # Your API token
  -dt, [--domain-token=DOMAIN_TOKEN]         # Your Domain API token
      [--sandbox], [--no-sandbox]            # Use sandbox API(at sandbox.dnsimple.com)
                                             # Default: true
      [--debug], [--no-debug]

Apply domain specifications
```

#### help export

```
$ dslimple help export
Usage:
  dslimple export

Options:
  -o, [--only=one two three]             # Specify domains for export
  -f, [--file=FILE]                      # Export Domainfile path
                                         # Default: Domainfile
  -d, [--dir=DIR]                        # Export directory path for split
                                         # Default: ./domainfiles
  -s, [--split], [--no-split]            # Export with split by domains
  -m, [--modeline], [--no-modeline]      # Export with modeline for Vim
      [--soa-and-ns], [--no-soa-and-ns]  # Export without SOA and NS records
  -e, [--email=EMAIL]                    # Your E-Mail address
  -t, [--api-token=API_TOKEN]            # Your API token
  -dt, [--domain-token=DOMAIN_TOKEN]     # Your Domain API token
      [--sandbox], [--no-sandbox]        # Use sandbox API(at sandbox.dnsimple.com)
                                         # Default: true
      [--debug], [--no-debug]

Export domain specifications
```

## Domainfile Examples

### Basic

The following defines are all the same meaning

```ruby
domain "example.com" do
  a_record ttl: 3600 do
    "0.0.0.0"
  end

  record type: :a, ttl: 3600 do
    "0.0.0.0"
  end

  a_record do
    ttl 3600
    content "0.0.0.0"
  end
end
```

### Dynamic

DSLimple's DSL works on ruby.

```ruby
require 'open-uri'
require 'json'

domain "example.internal" do
  JSON.parse(open('http://my.internal.service/records.json', &:read)).each do |record_data|
    recored record_data['name'], record_data['options'] { record_data['content'] }
  end
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zeny-io/dslimple.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

## Inspired by

- [roadworker](https://github.com/winebarrel/roadworker)

