require 'net/http'
require 'addressable/uri'
require 'json'

class NamecoinClient
  Error = Class.new(RuntimeError)

  attr_accessor :uri

  def initialize(uri = "http://127.0.0.1:19920/")
    @uri = Addressable::URI.parse(uri.to_s)
    get_auth_from_namecoin_conf unless @uri.user && @uri.password
  end

  def get_auth_from_namecoin_conf
    open File.expand_path("~/.namecoin/bitcoin.conf") do |file|
      while line = file.gets
        case line
        when /rpcconnect=(\S+)/
          uri.host = $1
        when /rpcport=(\S+)/
          uri.port = $1.to_i
        when /rpcuser=(\S+)/
          uri.user = $1
        when /rpcpassword=(\S+)/
          uri.password = $1
        end
      end
    end
  end

  def request(method, *params)
    req = Net::HTTP::Post.new(uri.path)
    req.basic_auth uri.user, uri.password
    req.content_type = 'application/json'
    req.body = {
      jsonrpc: '1.0',
      id: 'NamecoinClient',
      method: method,
      params: params,
    }.to_json

    res = Net::HTTP.new(uri.host, uri.port).start{|http| http.request(req) }

    case res
    when Net::HTTPSuccess
      body = JSON.parse(res.body)

      if error = body['error']
        raise Error, error
      else
        body['result']
      end
    else
      res.error!
    end
  end

  # Safely copies wallet.dat to destination, which can be a directory or a path with filename.
  def backupwallet(destination)
    request(:backupwallet, destination)
  end

  # Returns the account associated with the given address.
  def getaccount(namecoin_address)
    request :getaccount, namecoin_address
  end
  alias get_account getaccount

  # Returns the current namecoin address for receiving payments to this account.
  def getaccountaddress(account)
    request :getaccountaddress, account
  end

  # Returns the list of addresses for the given account.
  def getaddressesbyaccount(account)
    request :getaddressesbyaccount, account
  end

  # If [account] is not specified, returns the server's total available balance.
  # If [account] is specified, returns the balance in the account.
  def getbalance(account = nil, minconf = 1)
    request :getbalance, account, minconf
  end
  alias balance getbalance

  # Dumps the block existing at specified height. Note: this is not available in the official release
  def getblockbycount(height)
    request :getblockbycount, height
  end

  # Returns the number of blocks in the longest block chain.
  def getblockcount
    request :getblockcount
  end

  # Returns the block number of the latest block in the longest block chain.
  def getblocknumber
    request :getblocknumber
  end

  # Returns the number of connections to other nodes.
  def getconnectioncount
    request :getconnectioncount
  end

  #  Returns the proof-of-work difficulty as a multiple of the minimum difficulty.
  def getdifficulty
    request :getdifficulty
  end

  # Returns true or false whether namecoind is currently generating hashes
  def getgenerate
    request :getgenerate
  end

  # Returns a recent hashes per second performance measurement while generating.
  def gethashespersec
    request :gethashespersec
  end

  # Returns an object containing various state info.
  def getinfo
    request :getinfo
  end
  alias info getinfo

  #  Returns a new namecoin address for receiving payments. If [account] is
  #  specified (recommended), it is added to the address book so payments
  #  received with the address will be credited to [account].
  def getnewaddress(account = nil)
    request :getnewaddress, account
  end
  alias new_address getnewaddress

  # Returns the total amount received by addresses with <account> in
  # transactions with at least [minconf] confirmations.
  def getreceivedbyaccount(account, minconf = 1, includeemepty = false)
    request :getreceivedbyaccount, minconf, includeemepty
  end
  alias received_by_account getreceivedbyaccount

  # Returns the total amount received by <namecoinaddress> in transactions with at least [minconf] confirmations.
  def getreceivedbyaddress(namecoin_address, minconf = 1, includeemepty = false)
    request :namecoin_address, minconf, includeemepty
  end
  alias received_by_address getreceivedbyaddress

  # Get detailed information about <txid>
  def gettransaction(txid)
    request :gettransaction, txid
  end
  alias get_transaction gettransaction

  # List commands, or get help for a command.
  def help(command = nil)
    request :help, *command
  end

  # If [data] is not specified, returns formatted hash data to work on:
  #
  # "midstate" : precomputed hash state after hashing the first half of the data
  # "data" : block data
  # "hash1" : formatted hash buffer for second hash
  # "target" : little endian hash target
  # If [data] is specified, tries to solve the block and returns true if it was successful.
  def getwork(data)
    request :getwork, data
  end
  alias work getwork

  def listaccounts(minconf = 1)
    request :listaccounts, minconf
  end
  alias list_accounts listaccounts

  # Returns an array of objects containing:
  #
  #   "account" : the account of the receiving addresses
  #   "amount" : total amount received by addresses with this account
  #   "confirmations" : number of confirmations of the most recent transaction included
  def listreceivedbyaccount(minconf = 1, includeemepty = false)
    request :listreceivedbyaccount, minconf, includeemepty
  end
  alias list_received_by_account listreceivedbyaccount

  #   Returns an array of objects containing:
  #     "address" : receiving address
  #     "account" : the account of the receiving address
  #     "amount" : total amount received by the address
  #     "confirmations" : number of confirmations of the most recent transaction included
  #
  # To get a list of accounts on the system, execute namecoind listreceivedbyaddress 0 true
  def listreceivedbyaddress(minconf = 1, includeemepty = false)
    request :listreceivedbyaddress, minconf, includeemepty
  end
  alias list_received_by_address listreceivedbyaddress

  # Returns up to [count] most recent transactions for account <account>.
  def listtransactions(account, count = 10)
    request :listtransactions, account, count
  end
  alias list_transactions listtransactions

  # Move from one account in your wallet to another.
  def move(from_account, to_account, amount, minconf = 1, comment = nil)
    request :move, from_account, to_account, amount, minconf, comment
  end

  # <amount> is a real and is rounded to the nearest 0.01
  def sendfrom(from_account, to_namecoin_address, amount, minconf = 1, comment = nil, comment_to = nil)
    request :sendfrom, from_account, to_namecoin_address, amount, minconf, comment, comment_to
  end
  alias send_from sendfrom

  # <amount> is a real and is rounded to the nearest 0.01
  def sendtoaddress(namecoin_address, amount, comment = nil, comment_to = nil)
    request :sendtoaddress, namecoin_address, amount, comment, comment_to
  end
  alias send_to_address sendtoaddress

  # Sets the account associated with the given address.
  def setaccount(namecoin_address, account)
    request :setaccount, namecoin_address, account
  end
  alias set_account setaccount

  # <generate> is true or false to turn generation on or off.
  # Generation is limited to [genproclimit] processors, -1 is unlimited.
  def setgenerate(generate, genproclimit)
    request :setgenerate, generate, genproclimit
  end
  alias set_generate setgenerate

  # Stop namecoin server.
  def stop
    request :stop
  end

  # Return information about <namecoinaddress>.
  def validateaddress(namecoin_address)
    request :validateaddress, namecoin_address
  end
  alias validate_address validateaddress

  def name_clean(name)
    request :name_clean, name
  end

  def name_firstupdate(name, rand, tx = nil, value)
    request :name_firstupdate, name, rand, *[tx, value].compact
  end

  def name_list(name = nil)
    request :name_list, name
  end

  def name_new(name)
    request :name_new, name
  end

  def name_scan(start_name = nil, max_returned = 1)
    request :name_scan, start_name, max_returned
  end

  def name_update(name, value, to_address = nil)
    request :name_update, name, value, to_address
  end
end

if __FILE__ == $0
  require 'pp'

  client = NamecoinClient.new
  puts client.help
  p client.name_scan('d/rubyists')
end
