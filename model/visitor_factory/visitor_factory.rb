require 'trollop'
require 'eventmachine'
require 'em/threaded_resource'
require_relative '../../lib/flow'
require_relative '../../lib/logging'
require_relative '../../lib/error'
require_relative '../../model/monitoring/public'


class VisitorFactory
  #----------------------------------------------------------------------------------------------------------------
  # include class
  #----------------------------------------------------------------------------------------------------------------
  include EM::Deferrable
  include Errors
  #----------------------------------------------------------------------------------------------------------------
  # Exception message
  #----------------------------------------------------------------------------------------------------------------
  class VisitorFactoryError < Error

  end

  ARGUMENT_UNDEFINE = 1000

  #----------------------------------------------------------------------------------------------------------------
  # constant
  #----------------------------------------------------------------------------------------------------------------
  VISITOR_BOT = Pathname(File.join(File.dirname(__FILE__), "..", "..", "run", "visitor_bot.rb")).realpath
  TMP = Pathname(File.join(File.dirname(__FILE__), "..","..", "tmp")).realpath
  OK = 0

  #----------------------------------------------------------------------------------------------------------------
  # attribut
  #----------------------------------------------------------------------------------------------------------------
  attr :pattern,
       :use_proxy_system,
       :port_proxy_sahi,
       :runtime_ruby,
       :default_ip_geo,
       :default_port_geo,
       :default_user_geo,
       :default_pwd_geo,
       :default_type_geo,
       :logger

  #----------------------------------------------------------------------------------------------------------------
  # class methods
  #----------------------------------------------------------------------------------------------------------------


  #----------------------------------------------------------------------------------------------------------------
  # instance methods
  #----------------------------------------------------------------------------------------------------------------

  #-----------------------------------------------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------------------------------------------
  # input : hash decrivant les propriétés du browser de la visit
  # :name : Internet Explorer
  # :version : '9.0'
  # :operating_system : Windows
  # :operating_system_version : '7'
  # :flash_version : 11.7 r700   -- not use
  # :java_enabled : 'Yes'        -- not use
  # :screens_colors : 32-bit     -- not use
  # :screen_resolution : 1600 x900
  # output : un objet Browser
  # exception :
  # StandardError :
  # si le listening_port_proxy n'est pas defini
  # si la resoltion d'ecran du browser n'est pas definie
  #-----------------------------------------------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------------------------------------------
  def initialize(browser, version, use_proxy_system, port_proxy_sahi, runtime_ruby, delay_periodic_scan, default_geolocation, logger)
    @use_proxy_system = use_proxy_system
    @port_proxy_sahi = port_proxy_sahi
    @runtime_ruby = runtime_ruby
    @pattern = "#{browser} #{version}" # ne pas supprimer le blanc
    @pool = EM::Pool.new
    @delay_periodic_scan = delay_periodic_scan
    @default_type_geo = default_geolocation[:proxy_type]
    @logger = logger

    if @default_type_geo != "none"
      @default_ip_geo = default_geolocation[:proxy_ip]
      @default_port_geo = default_geolocation[:proxy_port]
      @default_user_geo = default_geolocation[:proxy_user]
      @default_pwd_geo = default_geolocation[:proxy_pwd]
    end

    @port_proxy_sahi.each { |port|
      visitor_instance = EM::ThreadedResource.new do
        {:pattern => @pattern, :port_proxy_sahi => port}
      end
      @pool.add visitor_instance
    }
    @logger.an_event.info "ressource #{@pattern} is on"
  end

  #-----------------------------------------------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------------------------------------------
  # input : hash decrivant les propriétés du browser de la visit
  # :name : Internet Explorer
  # :version : '9.0'
  # :operating_system : Windows
  # :operating_system_version : '7'
  # :flash_version : 11.7 r700   -- not use
  # :java_enabled : 'Yes'        -- not use
  # :screens_colors : 32-bit     -- not use
  # :screen_resolution : 1600 x900
  # output : un objet Browser
  # exception :
  # StandardError :
  # si le listening_port_proxy n'est pas defini
  # si la resoltion d'ecran du browser n'est pas definie
  #-----------------------------------------------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------------------------------------------
  def scan_visit_file
    begin
      EM::PeriodicTimer.new(@delay_periodic_scan) do
        @logger.an_event.info "scan visit flow for #{@pattern} in #{TMP}"
        tmp_flow_visit = Flow.first(TMP, {:type_flow => @pattern, :ext => "yml"})


        if !tmp_flow_visit.nil?
          tmp_flow_visit.archive
          @logger.an_event.info "visit flow #{tmp_flow_visit.basename} archive"
          @pool.perform do |dispatcher|
            dispatcher.dispatch do |details|
              details[:visit_file] = tmp_flow_visit.absolute_path

              start_visitor_bot(details)
            end
          end
        end
      end
    rescue Exception => e
      @logger.an_event.error "scan visit file for #{@pattern} catch exception : #{e.message} => restarting"
      retry
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------------------------------------------
  # input : hash decrivant les propriétés du browser de la visit
  # :name : Internet Explorer
  # :version : '9.0'
  # :operating_system : Windows
  # :operating_system_version : '7'
  # :flash_version : 11.7 r700   -- not use
  # :java_enabled : 'Yes'        -- not use
  # :screens_colors : 32-bit     -- not use
  # :screen_resolution : 1600 x900
  # output : un objet Browser
  # exception :
  # StandardError :
  # si le listening_port_proxy n'est pas defini
  # si la resoltion d'ecran du browser n'est pas definie
  #-----------------------------------------------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------------------------------------------
  def start_visitor_bot(details)

    begin
      @logger.an_event.info "start visitor_bot with browser #{details[:pattern]} and visit file #{details[:visit_file]}"
      cmd = "#{@runtime_ruby} -e $stdout.sync=true;$stderr.sync=true;load($0=ARGV.shift)  #{VISITOR_BOT} -v #{details[:visit_file]} -t #{details[:port_proxy_sahi]} -p #{@use_proxy_system} #{geolocation}"
      @logger.an_event.debug "cmd start visitor_bot #{cmd}"

      pid = Process.spawn(cmd)
      pid, status = Process.wait2(pid, 0)
    rescue Exception => e
      @logger.an_event.error "start visitor_bot with browser #{details[:pattern]} and visit file #{details[:visit_file]} failed : #{e.message}"
    else
      unless status.exitstatus == OK
        @@logger.an_event.error "visitor_bot  browser #{details[:pattern]} port #{details[:port_proxy_sahi]} send an error to monitoring"
      end
      if status.exitstatus == OK
        Monitoring.send_success(@logger)
      end
    end
  end

  #-----------------------------------------------------------------------------------------------------------------
  # initialize
  #-----------------------------------------------------------------------------------------------------------------
  # input : hash decrivant les propriétés du browser de la visit
  # :name : Internet Explorer
  # :version : '9.0'
  # :operating_system : Windows
  # :operating_system_version : '7'
  # :flash_version : 11.7 r700   -- not use
  # :java_enabled : 'Yes'        -- not use
  # :screens_colors : 32-bit     -- not use
  # :screen_resolution : 1600 x900
  # output : un objet Browser
  # exception :
  # StandardError :
  # si le listening_port_proxy n'est pas defini
  # si la resoltion d'ecran du browser n'est pas definie
  #-----------------------------------------------------------------------------------------------------------------
  #
  #-----------------------------------------------------------------------------------------------------------------
  def geolocation
    #TODO reviser le calcul de la geolocation avec les proxy furtur ; pour le moment soit pas de geolocation soit une seule
    # si @default_type_geo == "none" => aucun proxy
    # si @default_type_geo <> "none" => proxy
    #     si @default_ip_geo == nil et @default_port_geo == nil alors il faut calculer un proxy de geolocation
    #     sinon utilise le proxy de l'entreprise passé en paramètre
    #geolocation = "-r http -o muz11-wbsswsg.ca-technologies.fr -x 8080 -y ET00752 -w Bremb@08"
    case @default_type_geo
      when "none"
        return ""
      else
        if @default_ip_geo.nil? and @default_port_geo.nil?
          #TODO recupere un proxy de geolocation
        else
          return "-r #{@default_type_geo} -o #{@default_ip_geo} -x #{@default_port_geo} -y #{@default_user_geo} -w #{@default_pwd_geo}"
        end
    end
  end
end
