# TODO: handle errors during logger.event
module Woodsman
  describe Logger do
    let!(:stdout_spy) { spy }
    let!(:logger) { Woodsman.logger = Logger.new(stdout_spy) }

    after :each do
      logger.clear_diagnostic_contexts(all=true)
      Woodsman.logger = Logger.new(nil)
    end

    describe '.flatten_context' do
      it "flattens a hash" do
        expect(Logger.flatten_context({'key1' => 'value', :key2 => 'value2'})).to eq(" key1=value key2=value2")
      end

      it "flattens a hash with special characters" do
        expect(Logger.flatten_context({'key1' => 'test value', :key2 => 'a=b'})).to eq(" key1=test&#32;value key2=a&#61;b")
      end
    end

    it 'finishes logging 5000 lines with scrubbing in less than 1s' do
      expected_scrub_time = 200.0

      count = 1000
      log = Logger.new(stdout_spy)
      log.scrubbers << Scrubbers::KeyValueScrubber.new('password_kv_scrubber', 'password', 'XYZ')
      log.scrubbers << Scrubbers::KeyValueScrubber.new('email_kv_scrubber', :email, 'XYZ')
      log.scrubbers << Scrubbers::SsnScrubber.new

      elapsed_time = 1000 * Benchmark.realtime do
        count.times do
          log.debug 'Hello world there is nothing to scrub here.'
          log.info 'Got an SSN of 555-55-5555'
          log.info 'password=hello 555-55-5555 and password=what'
          log.info 'Got an SSN of 555-55-5555 and password=test'
          log.event 'new_user', {slug: 'jane', ssn: '555-55-5555', password: 'iforgot'}, 'Added Jane.'
        end
      end

      puts "scrub_time_ms=#{elapsed_time} expected_scrub_time_ms=#{expected_scrub_time} log_lines=#{count*5}" if (elapsed_time - expected_scrub_time).abs > 50.0

      expect(elapsed_time).to be < 1000
    end

    it 'has scrubbers by default' do
      new_logger = Logger.new(stdout_spy)

      expect(new_logger.scrubber_names.size).to be >= 5
    end

    it 'has the ssn scrubber if initialized with common scrubbers' do
      new_logger = Logger.new(stdout_spy, add_common_scrubbers: true)

      expect(new_logger.scrubber_names.include? 'ssn_scrubber').to eq(true)
    end

    it 'handles the degenerate case where context and msg are explicitly nil' do
      logger.event 'hi', nil, nil

      expect(stdout_spy).to have_received(:info).with('event=hi')
    end

    it 'clears scrubbers' do
      logger.scrubbers.clear
      expect(logger.scrubber_names.join(',')).to be_empty

      logger.scrubbers << Scrubbers::KeyValueScrubber.new('password_kv_scrubber', 'password', 'XYZ')
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('email_kv_scrubber', :email, 'XYZ')
      logger.scrubbers << Scrubbers::SsnScrubber.new

      expect(logger.scrubber_names.join(',')).to eq('password_kv_scrubber,email_kv_scrubber,ssn_scrubber')

      logger.scrubbers.clear

      expect(logger.scrubber_names.join(',')).to be_empty
    end

    it 'scrubs xml element contents with newlines' do
      logger.scrubbers << Scrubbers::XmlElementScrubber.new('xml_element_password', 'password', 'XXXXX')

      request = %Q{<?xml version="1.0"><link><username xsi:type="login">jane888</username>\n<password>\t\topen\nsesame</password>}
      response = '<?xml version="1.0"><linkResponse status="500">Unable to link</linkResponse>'
      logger.event 'yodlee_failed', {request: request, response: response}, 'Unable to link account due to server error.'

      expect(stdout_spy).to have_received(:info).with("event=yodlee_failed Unable to link account due to server error. request=<?xml&#32;version&#61;\"1.0\"><link><username&#32;xsi:type&#61;\"login\">jane888</username>\n<password>XXXXX</password> response=<?xml&#32;version&#61;\"1.0\"><linkResponse&#32;status&#61;\"500\">Unable&#32;to&#32;link</linkResponse>")
    end

    it 'scrubs xml element contents' do
      logger.scrubbers << Scrubbers::XmlElementScrubber.new('xml_element_password', 'password', 'XXXXX')

      request = '<?xml version="1.0"><link><username xsi:type="login">jane888</username><password>open sesame</password>'
      response = '<?xml version="1.0"><linkResponse status="500">Unable to link</linkResponse>'
      logger.event 'yodlee_failed', {request: request, response: response}, 'Unable to link account due to server error.'

      expect(stdout_spy).to have_received(:info).with('event=yodlee_failed Unable to link account due to server error. request=<?xml&#32;version&#61;"1.0"><link><username&#32;xsi:type&#61;"login">jane888</username><password>XXXXX</password> response=<?xml&#32;version&#61;"1.0"><linkResponse&#32;status&#61;"500">Unable&#32;to&#32;link</linkResponse>')
    end

    it 'scrubs xml element contents with attributes' do
      logger.scrubbers << Scrubbers::XmlElementScrubber.new('xml_element_password', 'password', 'XXXXX')

      request = '<?xml version="1.0"><link><username xsi:type="login">jane888</username><password xsi:type="securepw">open sesame</password>'
      response = '<?xml version="1.0"><linkResponse status="500">Unable to link</linkResponse>'
      logger.event 'yodlee_failed', {request: request, response: response}, 'Unable to link account due to server error.'

      expect(stdout_spy).to have_received(:info).with('event=yodlee_failed Unable to link account due to server error. request=<?xml&#32;version&#61;"1.0"><link><username&#32;xsi:type&#61;"login">jane888</username><password&#32;xsi:type&#61;"securepw">XXXXX</password> response=<?xml&#32;version&#61;"1.0"><linkResponse&#32;status&#61;"500">Unable&#32;to&#32;link</linkResponse>')
    end

    it 'scrubs event context data' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('password_kv_scrubber', 'password', 'XYZ')
      logger.scrubbers << Scrubbers::SsnScrubber.new

      logger.event 'new_user', {user_slug: 'jane', ssn: '555-55-5555', password: 'opensesame'}, 'Added jane.'

      expect(stdout_spy).to have_received(:info).with('event=new_user Added jane. user_slug=jane ssn=XXX-XX-XXXX password=XYZ')
    end

    it 'scrubs marketo specific info data' do
      request = {:lead_record => {:Email => "afeefadd@asdadsfad.com", :lead_attribute_list => {:attribute => [{:attr_type => "string", :attr_name => "uuid", :attr_value => "9cd0ae89-849f-4f7d-81ab-131a6ded0675"}, {:attr_type => "string", :attr_name => "leadState", :attr_value => "lead_collected"}, {:attr_type => "string", :attr_name => "gclid", :attr_value => ""}, {:attr_type => "string", :attr_name => "marketingProspection", :attr_value => nil}, {:attr_type => "string", :attr_name => "Email", :attr_value => "afeefadd@asdadsfad.com"}]}}, :return_lead => true}
      logger.scrubbers << Scrubbers::RegexLineScrubber.new(:marketo_email_scrubber_1, /(:Email=>").*?(?=")/i, '\1****')
      logger.info "Marketo request parameters: #{request}"

      logger.scrubbers << Scrubbers::RegexLineScrubber.new(:marketo_email_scrubber_2, /(:attr_name=>"Email", :attr_value=>").*?(?=")/i, '\1****')
      logger.info "Marketo request parameters: #{request}"

      expect(stdout_spy).to have_received(:info).with('Marketo request parameters: {:lead_record=>{:Email=>"****", :lead_attribute_list=>{:attribute=>[{:attr_type=>"string", :attr_name=>"uuid", :attr_value=>"9cd0ae89-849f-4f7d-81ab-131a6ded0675"}, {:attr_type=>"string", :attr_name=>"leadState", :attr_value=>"lead_collected"}, {:attr_type=>"string", :attr_name=>"gclid", :attr_value=>""}, {:attr_type=>"string", :attr_name=>"marketingProspection", :attr_value=>nil}, {:attr_type=>"string", :attr_name=>"Email", :attr_value=>"afeefadd@asdadsfad.com"}]}}, :return_lead=>true}')
      expect(stdout_spy).to have_received(:info).with('Marketo request parameters: {:lead_record=>{:Email=>"****", :lead_attribute_list=>{:attribute=>[{:attr_type=>"string", :attr_name=>"uuid", :attr_value=>"9cd0ae89-849f-4f7d-81ab-131a6ded0675"}, {:attr_type=>"string", :attr_name=>"leadState", :attr_value=>"lead_collected"}, {:attr_type=>"string", :attr_name=>"gclid", :attr_value=>""}, {:attr_type=>"string", :attr_name=>"marketingProspection", :attr_value=>nil}, {:attr_type=>"string", :attr_name=>"Email", :attr_value=>"****"}]}}, :return_lead=>true}')
    end

    it 'scrubs context data' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('password_kv_scrubber', 'password', 'XYZ')
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('email_kv_scrubber', :email, 'XYZ')
      logger.scrubbers << Scrubbers::SsnScrubber.new

      logger.mdc['user_slug'] = 'jane'
      logger.mdc['ssn'] = '555-55-5555'
      logger.mdc['email'] = 'jane+test@woodsman.com'
      logger.mdc[:password] = 'opensesame'

      logger.debug('Found user.')

      expect(stdout_spy).to have_received(:debug).with('Found user. user_slug=jane ssn=XXX-XX-XXXX email=XYZ password=XYZ')
    end

    it 'scrubs context key/value with a strongly typed scrubber' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.event 'new_user', {slug: 'jane', key: 'abacadabra'}, 'Added Jane.'

      expect(stdout_spy).to have_received(:info).with('event=new_user Added Jane. slug=jane key=XYZ')
    end

    it 'scrubs log line with a strongly typed scrubber' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info 'my secret key=abacadabra and you will never find out'

      expect(stdout_spy).to have_received(:info).with('my secret key=XYZ and you will never find out')
    end

    it 'scrubs log line with newlines with a strongly typed scrubber' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info "my secret\nkey=abacadabra and you will never find out"

      expect(stdout_spy).to have_received(:info).with("my secret\nkey=XYZ and you will never find out")
    end

    it 'scrubs log line with a strongly typed scrubber and start of line match' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info 'key=abacadabra and you will never find out'

      expect(stdout_spy).to have_received(:info).with('key=XYZ and you will never find out')
    end

    it 'scrubs log line with a strongly typed scrubber and end of line match' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info 'i cannot remember my key=abacadabra'

      expect(stdout_spy).to have_received(:info).with('i cannot remember my key=XYZ')
    end

    it 'scrubs log line with a strongly typed scrubber and full match' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info 'key=abacadabra'

      expect(stdout_spy).to have_received(:info).with('key=XYZ')
    end

    it 'does not scrub log line with a strongly typed scrubber on a suffix match' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info 'safe_key=knock'

      expect(stdout_spy).to have_received(:info).with('safe_key=knock')
    end

    it 'scrubs log line with a strongly typed scrubber and no match' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info ''

      expect(stdout_spy).to have_received(:info).with('')
    end

    it 'scrubs log line with a strongly typed scrubber and multiple matches' do
      logger.scrubbers << Scrubbers::KeyValueScrubber.new('key_scrubber', :key, 'XYZ')
      logger.info 'key=1 key=abc key=hello and key=red12412!$E@'

      expect(stdout_spy).to have_received(:info).with('key=XYZ key=XYZ key=XYZ and key=XYZ')
    end

    it 'scrubs context value lines with a scrub block' do
      logger.scrubbers << Scrubbers::SsnScrubber.new
      logger.event 'new_user', {slug: 'jane', ssn: '555-55-5555', beneficiary: '555-55-5555'}, 'Added Jane.'

      expect(stdout_spy).to have_received(:info).with('event=new_user Added Jane. slug=jane ssn=XXX-XX-XXXX beneficiary=XXX-XX-XXXX')
    end

    it 'scrubs log lines with a SSN scrubber' do
      logger.scrubbers << Scrubbers::SsnScrubber.new
      logger.info 'his ssn is 555-55-5555'

      expect(stdout_spy).to have_received(:info).with('his ssn is XXX-XX-XXXX')
    end

    it 'scrubs log lines with a regex scrubber' do
      logger.scrubbers << Scrubbers::RegexLineScrubber.new('red_scrubber', /red/, 'XYZ')
      logger.info 'i do not want to see red'

      expect(stdout_spy).to have_received(:info).with('i do not want to see XYZ')
    end

    it 'scrubs log lines with a scrub block' do
      logger.scrubbers << Scrubbers::GenericScrubber.new('generic_ssn_scrubber') { |l, c| next l.gsub(/\d{3}\-\d{2}\-\d{4}/, 'XXX-XX-XXXX'), c }

      logger.info 'my ssn is 555-55-5555'

      expect(stdout_spy).to have_received(:info).with('my ssn is XXX-XX-XXXX')
    end

    it 'silences log lines with the substring silencer' do
      logger.scrubbers << Scrubbers::SubstringSilencer.new('health_check_200_silencer', 'method=GET path=/health_check format=html controller=health_check/health_check action=index status=200')
      logger.info 'method=GET path=/health_check format=html controller=health_check/health_check action=index status=200'

      expect(stdout_spy).not_to have_received(:info)
    end

    it 'silences log lines with the regex silencer' do
      logger.scrubbers << Scrubbers::RegexSilencer.new('health_check_200_silencer', /health_check.*status=200/)
      logger.info 'method=GET path=/health_check format=html controller=health_check/health_check action=index status=200'

      expect(stdout_spy).not_to have_received(:info)
    end

    it 'logs common priorities' do
      logger.debug 'pld'
      logger.info 'pli'
      logger.error 'ple'
      logger.fatal 'plf'

      expect(stdout_spy).to have_received(:debug).with('pld')
      expect(stdout_spy).to have_received(:info).with('pli')
      expect(stdout_spy).to have_received(:error).with(/logger.*rb.*in `.*' ple/)
      expect(stdout_spy).to have_received(:fatal).with(/logger.*rb.*in `.*' plf/)
    end

    it 'logs common priorities using the direct class method' do
      Woodsman.logger.debug 'pld'
      Woodsman.logger.info 'pli'
      Woodsman.logger.error 'ple'
      Woodsman.logger.fatal 'plf'

      expect(stdout_spy).to have_received(:debug).with('pld')
      expect(stdout_spy).to have_received(:info).with('pli')
      expect(stdout_spy).to have_received(:error).with(/logger.*rb.*in `.*' ple/)
      expect(stdout_spy).to have_received(:fatal).with(/logger.*rb.*in `.*' plf/)
    end

    it 'logs exceptions' do
      begin
        raise 'fake error'
      rescue => e
        logger.error_exception 'An error was found.', e
        logger.fatal_exception 'oh noez, it was fatal!', e
      end

      expect(stdout_spy).to have_received(:error).with(/logger.*rb.*in `rescue in .*' An error was found. exception=fake error\nstacktrace=.*/)
      expect(stdout_spy).to have_received(:fatal).with(/logger.*rb.*in `rescue in .*' oh noez, it was fatal! exception=fake error\nstacktrace=.*/)
    end

    it 'silences backtraces' do
      logger.event 'layer1' do
        logger.event 'layer2' do
          logger.event 'layer3' do
            begin
              raise 'fake error'
            rescue => e
              logger.error_exception 'Nested error with silenced backtrace.', e
            end
          end
        end
      end

      expect(stdout_spy).to have_received(:info).with(/event=layer3 elapsed_time=\d\.\d+/)
      expect(stdout_spy).to have_received(:info).with(/event=layer2 elapsed_time=\d\.\d+/)
      expect(stdout_spy).to have_received(:info).with(/event=layer2 elapsed_time=\d\.\d+/)
      expect(stdout_spy).to have_received(:error).with(having_number_of_lines_less_than(10))
    end

    it 'supports loud backtraces' do
      logger.backtrace_cleaner = nil
      logger.event 'layer1' do
        logger.event 'layer2' do
          logger.event 'layer3' do
            begin
              raise "fake error"
            rescue => e
              logger.error_exception 'Nested error with silenced backtrace.', e
            end
          end
        end
      end

      expect(stdout_spy).to have_received(:info).with(/event=layer3 elapsed_time=\d\.\d+/)
      expect(stdout_spy).to have_received(:info).with(/event=layer2 elapsed_time=\d\.\d+/)
      expect(stdout_spy).to have_received(:info).with(/event=layer2 elapsed_time=\d\.\d+/)
      expect(stdout_spy).to have_received(:error).with(having_number_of_lines_greater_than(10))
    end

    it 'allows scrubbers and backtrace cleaner to be configured on instantiation' do
      log = Logger.new(stdout_spy, false, false)
      expect(log.backtrace_cleaner).to be_nil
      expect(log.scrubbers.size).to eq(0)

      log = Logger.new(stdout_spy, false, true)
      expect(log.backtrace_cleaner).to be
      expect(log.scrubbers.size).to eq(0)

      log = Logger.new(stdout_spy, true, false)
      expect(log.backtrace_cleaner).to be_nil
      expect(log.scrubbers.size).to be >= 5

      log = Logger.new(stdout_spy, true, true)
      expect(log.backtrace_cleaner).to be
      expect(log.scrubbers.size).to be >= 5
    end

# Hmm... It occurs to me after the fact that I could spy the timer, but unless you're stepping through the code w/ a
# debugger, I don't think there's much point in this instance.
    it 'logs timed blocks' do
      logger.timed 'Time me' do
        logger.debug 'Ready! Set! Go!'
        sleep 1
        logger.debug 'Done!'
      end

      expect(stdout_spy).to have_received(:debug).with('Ready! Set! Go!')
      expect(stdout_spy).to have_received(:debug).with('Done!')
      expect(stdout_spy).to have_received(:info).with(/Time me elapsed_time=10\d\d\.\d+/)
    end

    it 'logs timed blocks with exceptions' do
      expect {
        logger.timed 'Time me' do
          logger.debug 'Ready! Set! Go!'
          sleep 1
          raise 'I am a banana'
          logger.debug 'Done!'
        end
      }.to raise_exception(RuntimeError)

      expect(stdout_spy).to have_received(:debug).with('Ready! Set! Go!')
      expect(stdout_spy).not_to have_received(:debug).with('Done!')
      expect(stdout_spy).to have_received(:error).with(/Time me elapsed_time=10\d\d\.\d+/)
    end

    it 'logs blocks' do
      logger.debug { 'Foo debug' }
      logger.info { 'Foo info' }
      logger.error { 'Foo error' }
      logger.fatal { 'Foo fatal' }

      expect(stdout_spy).to have_received(:debug).with('Foo debug')
      expect(stdout_spy).to have_received(:info).with('Foo info')
      expect(stdout_spy).to have_received(:error).with(/Foo error/)
      expect(stdout_spy).to have_received(:fatal).with(/Foo fatal/)
    end

    it 'logs events' do
      logger.event :killer_block_party, 'Blockless party'

      expect(stdout_spy).to have_received(:info).with('event=killer_block_party Blockless party')
    end

    it 'logs events with attributes' do
      logger.event :killer_block_party, {time: '5pm', location: 'campus'}, 'Blockless party'

      expect(stdout_spy).to have_received(:info).with('event=killer_block_party Blockless party time=5pm location=campus')
    end

    it 'logs events with blocks' do
      logger.event 'killer_block_party2', 'All summer strong' do
        logger.debug "I'm in a block!"
      end

      expect(stdout_spy).to have_received(:debug).with("I'm in a block!")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party2 All summer strong elapsed_time=0.\d+/)
    end

    it 'logs events with blocks and attributes' do
      logger.event :killer_block_party3, {a: 1, b: 2, c: 3}, 'All summer gone' do
        logger.debug "I'm in a block!"
      end

      expect(stdout_spy).to have_received(:debug).with("I'm in a block!")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party3 All summer gone a=1 b=2 c=3 elapsed_time=0.\d+/)
    end

    it 'logged event blocks can update attributes' do
      log_data = {
          count: 0
      }

      logger.event :killer_block_party3, log_data, 'All summer gone' do
        log_data[:count] = 1
      end

      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party3 All summer gone count=1 elapsed_time=0.\d+/)
    end

    it 'logs with context' do
      logger.info "Starting context."
      logger.mdc['user'] = 'john'
      logger.mdc['ip'] = '127.0.0.1'
      logger.debug '1'
      logger.info '2'
      logger.mdc[:fail_count] = 1
      logger.error '3'
      logger.fatal '4'
      logger.timed "Time block" do
        logger.info "I'm in a block!"
      end

      expect(stdout_spy).to have_received(:info).with('Starting context.')
      expect(stdout_spy).to have_received(:debug).with('1 user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('2 user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:error).with(/.* 3 user=john ip=127.0.0.1 fail_count=1/)
      expect(stdout_spy).to have_received(:fatal).with(/.* 4 user=john ip=127.0.0.1 fail_count=1/)
      expect(stdout_spy).to have_received(:info).with("I'm in a block! user=john ip=127.0.0.1 fail_count=1")
      expect(stdout_spy).to have_received(:info).with(/Time block elapsed_time=0\.\d+ user=john ip=127.0.0.1 fail_count=1/)
    end

    it 'allows context to be cleared' do
      logger.mdc['user'] = 'john'
      logger.mdc['ip'] = '127.0.0.1'
      logger.debug 'With MDC'
      logger.timed "Time block" do
        logger.info "I'm in a block!"
      end
      logger.event :killer_block_party, "Blockless event"
      logger.clear_diagnostic_contexts true
      logger.info "Now without MDC."
      logger.timed "Block party w/o MDC" do
        logger.debug "So fast and so quick!"
      end
      logger.event :killer_block_party2, "All summer strong" do
        logger.debug "I'm in a block again!"
      end
      logger.event :killer_block_party3, {a: 1, b: 2, c: 3}, "All summer gone" do
        sleep 1
        logger.debug "I'm in a block!"
      end

      expect(stdout_spy).to have_received(:debug).with('With MDC user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with("I'm in a block! user=john ip=127.0.0.1")
      expect(stdout_spy).to have_received(:info).with(/Time block elapsed_time=0\.\d+ user=john ip=127.0.0.1/)
      expect(stdout_spy).to have_received(:info).with('event=killer_block_party Blockless event user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('Now without MDC.')

      expect(stdout_spy).to have_received(:debug).with('So fast and so quick!')
      expect(stdout_spy).to have_received(:info).with(/Block party w\/o MDC elapsed_time=0\.\d+/)

      expect(stdout_spy).to have_received(:debug).with("I'm in a block again!")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party2 All summer strong elapsed_time=0\.\d+/)
      expect(stdout_spy).to have_received(:debug).with("I'm in a block!")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party3 All summer gone a=1 b=2 c=3 elapsed_time=10\d\d\.\d+/)
    end

    it 'allows nested context to be cleared' do
      logger.ndc.push(user: 'john', ip: '127.0.0.1')
      logger.debug 'With NDC'
      logger.timed "Time block" do
        logger.info "I'm in a block!"
      end
      logger.event :killer_block_party, "Blockless event"
      logger.clear_diagnostic_contexts true
      logger.info "Now without NDC."
      logger.timed "Block party w/o NDC" do
        logger.debug "So fast and so quick!"
      end
      logger.event 'killer_block_party2', "All summer strong" do
        logger.debug "I'm in a block again!"
      end
      logger.event :killer_block_party3, {a: 1, b: 2, c: 3}, "All summer gone" do
        sleep 1
        logger.debug "I'm in a block!"
      end

      expect(stdout_spy).to have_received(:debug).with('With NDC user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with("I'm in a block! user=john ip=127.0.0.1")
      expect(stdout_spy).to have_received(:info).with(/Time block elapsed_time=0\.\d+ user=john ip=127.0.0.1/)
      expect(stdout_spy).to have_received(:info).with('event=killer_block_party Blockless event user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('Now without NDC.')
      expect(stdout_spy).to have_received(:debug).with('So fast and so quick!')
      expect(stdout_spy).to have_received(:info).with(/Block party w\/o NDC elapsed_time=0\.\d+/)
      expect(stdout_spy).to have_received(:debug).with("I'm in a block again!")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party2 All summer strong elapsed_time=0\.\d+/)
      expect(stdout_spy).to have_received(:debug).with("I'm in a block!")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party3 All summer gone a=1 b=2 c=3 elapsed_time=10\d\d\.\d+/)
    end

    it 'allows mixed context to be cleared' do
      logger.mdc[:ip] = '127.0.0.1'
      logger.ndc.push(user: 'john')
      logger.debug 'With MDC and NDC'
      logger.timed "Time block" do
        logger.info "I'm in a block!"
      end
      logger.event :killer_block_party, "Blockless event"
      logger.event 'killer_block_party2', "All summer strong" do
        logger.debug "I'm in a block again!"
      end
      logger.event :killer_block_party3, {a: 1, b: 2, c: 3}, "All summer gone" do
        sleep 1
        logger.debug "I'm in a block!"
      end
      logger.clear_diagnostic_contexts true
      logger.info "Now without MDC and NDC."
      logger.timed "Block party w/o MDC and NDC" do
        logger.debug "So fast and so quick!"
      end

      expect(stdout_spy).to have_received(:debug).with('With MDC and NDC user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with("I'm in a block! user=john ip=127.0.0.1")
      expect(stdout_spy).to have_received(:info).with(/Time block elapsed_time=0\.\d+ user=john ip=127.0.0.1/)
      expect(stdout_spy).to have_received(:info).with('event=killer_block_party Blockless event user=john ip=127.0.0.1')
      expect(stdout_spy).to have_received(:debug).with("I'm in a block again! user=john ip=127.0.0.1")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party2 All summer strong elapsed_time=0\.\d+ user=john ip=127.0.0.1/)
      expect(stdout_spy).to have_received(:debug).with("I'm in a block! user=john ip=127.0.0.1")
      expect(stdout_spy).to have_received(:info).with(/event=killer_block_party3 All summer gone a=1 b=2 c=3 elapsed_time=10\d\d\.\d+ user=john ip=127.0.0.1/)
      expect(stdout_spy).to have_received(:info).with('Now without MDC and NDC.')
      expect(stdout_spy).to have_received(:debug).with('So fast and so quick!')
      expect(stdout_spy).to have_received(:info).with(/Block party w\/o MDC and NDC elapsed_time=0\.\d+/)
    end

    it 'keeps nested context' do
      logger.info 'before ndc'
      logger.ndc.push({owner: 'woodsman'})
      logger.ndc.push({billable: false, insured: false})
      logger.info "Do some work outside"
      logger.ndc.push({owner: '3rd_party', billable: true})
      logger.info 'Inside 3rd Party'
      logger.ndc.pop
      logger.debug 'Not billable'
      logger.ndc.pop
      logger.info 'Done with Yodlee'

      expect(stdout_spy).to have_received(:info).with('before ndc')
      expect(stdout_spy).to have_received(:info).with('Do some work outside owner=woodsman billable=false insured=false')
      expect(stdout_spy).to have_received(:info).with('Inside 3rd Party owner=3rd_party billable=true insured=false')
      expect(stdout_spy).to have_received(:debug).with('Not billable owner=woodsman billable=false insured=false')
      expect(stdout_spy).to have_received(:info).with('Done with Yodlee owner=woodsman')
    end

    it 'supports multiple contexts' do
      logger.mdc['user_slug'] = 'jane'
      logger.info "about to go on a new thread"
      t1 = Thread.new do
        logger.info "Child thread"
        logger.mdc['child_name'] = 'Next generation thread'
        logger.info "I got fresh new context"
      end
      logger.info "Kicked off t1"
      t1.join
      logger.info "All back together"

      expect(stdout_spy).to have_received(:info).with('about to go on a new thread user_slug=jane')
      expect(stdout_spy).to have_received(:info).with('Child thread user_slug=jane')
      expect(stdout_spy).to have_received(:info).with('I got fresh new context user_slug=jane child_name=Next&#32;generation&#32;thread')
      expect(stdout_spy).to have_received(:info).with('Kicked off t1 user_slug=jane')
      expect(stdout_spy).to have_received(:info).with('All back together user_slug=jane')
    end

    it 'supports block NDC' do
      logger.with_context({user: 'jane', ip: '127.0.0.1'}) do
        logger.debug "hi"
        logger.with_context({transaction: 'abc'}) do
          logger.timed "Doing transaction" do
            logger.info "In transaction."
          end
          logger.info "done"
        end
        logger.debug "bye"
      end
      logger.info "finished"

      expect(stdout_spy).to have_received(:debug).with('hi user=jane ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with(/Doing transaction elapsed_time=0+\.\d+ user=jane ip=127.0.0.1 transaction=abc/)
      expect(stdout_spy).to have_received(:info).with('In transaction. user=jane ip=127.0.0.1 transaction=abc')
      expect(stdout_spy).to have_received(:info).with('done user=jane ip=127.0.0.1 transaction=abc')
      expect(stdout_spy).to have_received(:debug).with('bye user=jane ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('finished')
    end

    it 'loses all context without raising an error if cleared while inside a block NDC' do
      logger.debug 'start'
      logger.with_context({user: 'jane', ip: '127.0.0.1'}) do
        logger.info 'step1'
        logger.clear_diagnostic_contexts # Clients should *NOT* be doing this since it will mess up the NDC stack! :)
        logger.info 'step2'
      end

      logger.info 'done'

      expect(stdout_spy).to have_received(:debug).with('start')
      expect(stdout_spy).to have_received(:info).with('step1 user=jane ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('step2')
      expect(stdout_spy).to have_received(:info).with('done')
    end

    it 'loses all context without raising an error if cleared while inside a block NDC' do
      logger.debug 'start'
      logger.with_context({user: 'jane', ip: '127.0.0.1'}) do
        logger.info 'step1'
        logger.with_context({level: 2}) do
          logger.info 'step1.1'
          logger.clear_diagnostic_contexts # Clients should *NOT* be doing this fyi! :)
          logger.info 'step1.2'
        end
        logger.info 'step2'
      end

      logger.info 'done'

      expect(stdout_spy).to have_received(:debug).with('start')
      expect(stdout_spy).to have_received(:info).with('step1 user=jane ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('step1.1 user=jane ip=127.0.0.1 level=2')
      expect(stdout_spy).to have_received(:info).with('step1.2')
      expect(stdout_spy).to have_received(:info).with('step2')
      expect(stdout_spy).to have_received(:info).with('done')
    end

    it 'unwinds the nested context properly on error while inside a block NDC' do
      logger.debug 'start'
      logger.with_context({user: 'jane', ip: '127.0.0.1'}) do
        logger.info 'step1'
        begin
          logger.with_context({level: 2}) do
            logger.info 'step1.1'
            raise 'level 2 error'
            logger.info 'step1.2'
          end
        rescue => e
          # We won't do anything with the error. We just want to see if the logger unwound 1 level of the NDC.
        end

        logger.info 'step2'
      end

      logger.info 'done'

      expect(stdout_spy).to have_received(:debug).with('start')
      expect(stdout_spy).to have_received(:info).with('step1 user=jane ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('step1.1 user=jane ip=127.0.0.1 level=2')
      expect(stdout_spy).to have_received(:info).with('step2 user=jane ip=127.0.0.1')
      expect(stdout_spy).to have_received(:info).with('done')
    end

    it 'has only the caller in the prefix' do
      expect(logger.prefix(:error)).to match(/logger_spec/)
      expect(logger.prefix(:error)).not_to match(/logger\.rb/)
      expect(logger.prefix(:error)).not_to match(/woodsman\.rb/)
    end

    it 'allows events without messages' do
      logger.event 'evt1', {scale: 'huge', distance: 'far'}

      expect(stdout_spy).to have_received(:info).with('event=evt1 scale=huge distance=far')
    end

    it 'returns values from a logged event with a block' do
      ret = logger.event('evt1', {scale: 'huge', distance: 'far'}) do
        'retval'
      end

      expect(ret).to eq('retval')
      expect(stdout_spy).to have_received(:info).with(/event=evt1 scale=huge distance=far elapsed_time=0+\.\d+/)
    end

    it 'logs events when there are explicit returns from the log event block' do
      proc = -> do
        logger.event('evt1', {scale: 'huge', distance: 'far'}) do
          return 'fastretval'
          'retval'
        end
      end

      ret = proc.call

      expect(ret).to eq('fastretval')
      expect(stdout_spy).to have_received(:info).with(/event=evt1 scale=huge distance=far elapsed_time=0+\.\d+/)
    end

    it 'logs events when there are explicit breaks from the log event block' do
      ret = logger.event('evt1', {scale: 'huge', distance: 'far'}) do
        break 'fastretval'
        'retval'
      end

      expect(ret).to eq('fastretval')
      expect(stdout_spy).to have_received(:info).with(/event=evt1 scale=huge distance=far elapsed_time=0+\.\d+/)
    end

    it 'returns values from a timed block' do
      ret = logger.timed 'do something' do
        'retval'
      end

      expect(ret).to eq('retval')
      expect(stdout_spy).to have_received(:info).with(/do something elapsed_time=0+\.\d+/)
    end

    it 'allows log chaining' do
      ret = logger.info('Round 1').info('Round 2')

      expect(ret).to be
      expect(stdout_spy).to have_received(:info).with(/Round 1/)
      expect(stdout_spy).to have_received(:info).with(/Round 2/)
    end

    it 'returns a value after debug' do
      ret = logger.debug 'hi from debug'

      expect(ret).to be
      expect(stdout_spy).to have_received(:debug).with(/hi from debug/)
    end

    it 'returns a value after info' do
      ret = logger.info 'hi from info'

      expect(ret).to be
      expect(stdout_spy).to have_received(:info).with(/hi from info/)
    end

    it 'returns a value after error' do
      ret = logger.error 'hi from error'

      expect(ret).to be
      expect(stdout_spy).to have_received(:error).with(/hi from error/)
    end

    it 'returns a value after fatal' do
      ret = logger.fatal 'hi from fatal'

      expect(ret).to be
      expect(stdout_spy).to have_received(:fatal).with(/hi from fatal/)
    end

    it 'returns a value after error_exception' do
      begin
        raise 'raise an error'
      rescue => e
        ret = logger.error_exception 'hi from error_exception', e
      end

      expect(ret).to be
      expect(stdout_spy).to have_received(:error).with(/hi from error_exception/)
    end

    it 'returns a value after fatal_exception' do
      begin
        raise 'raise an error'
      rescue => e
        ret = logger.fatal_exception 'hi from fatal_exception', e
      end

      expect(ret).to be
      expect(stdout_spy).to have_received(:fatal).with(/hi from fatal_exception/)
    end

    it 'returns a value after event without a block' do
      ret = logger.event('evt1', {scale: 'huge', distance: 'far'})

      expect(ret).to be
      expect(stdout_spy).to have_received(:info).with(/event=evt1 scale=huge distance=far/)
    end

    it 'can mix in a log method' do
      o = Object.new
      o.extend(LogHelper)

      o.log.info 'using log method'
      expect(stdout_spy).to have_received(:info).with('using log method')
    end
  end
end
