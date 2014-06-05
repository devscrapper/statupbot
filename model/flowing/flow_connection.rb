require 'rubygems' # if you use RubyGems
require 'socket'
require 'eventmachine'
require_relative 'flow_list'

module Flowing
  class FlowConnection < EventMachine::Connection
    attr :logger


    def initialize(logger)
      @logger = logger
    end

    def receive_data param
      @logger.an_event.debug "data receive <#{param}>"
      begin
        Thread.new(Socket.unpack_sockaddr_in(get_peername)[1]) { |ip_ftp_server|

          begin
            data = YAML::load param
            data["data"].merge!({"ip_ftp_server" => ip_ftp_server})
            type_flow = data["type_flow"]
            data_type_flow = data["data"]
            @logger.an_event.debug data
            context = []
            context << type_flow
            @logger.ndc context
            @logger.an_event.debug "type_flow <#{type_flow}>"
            @logger.an_event.debug "data type_flow <#{data_type_flow}>"
            @logger.an_event.debug "context <#{context}>"
            @logger.an_event.info "receive flow <#{data_type_flow["basename"]}>"
#            Flowlist.new(data_type_flow).method(type_flow.gsub("-", "_")).call()
            Flowlist.new(data_type_flow).visit_flow

          rescue Exception => e
            @logger.an_event.error "cannot manage flow <#{type_flow.gsub("-", "_")}>"
            @logger.an_event.debug e
          end
        }
      rescue Exception => e
        @logger.an_event.error "cannot thread input flow"
        @logger.an_event.debug e
      end
      close_connection
    end


  end
end