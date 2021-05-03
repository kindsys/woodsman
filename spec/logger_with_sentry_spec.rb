# TODO: handle errors during logger.event
module Woodsman
  describe Logger do
    let!(:stdout_spy) { spy }
    let!(:logger) { Woodsman.logger = LoggerWithSentry.new(stdout_spy) }

    after :each do
      logger.clear_diagnostic_contexts(all=true)
      Woodsman.logger = LoggerWithSentry.new(nil)
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

    it 'logs exceptions' do
      begin
        raise 'fake error'
      rescue => e
        logger.error_exception 'An error was found.', e
        logger.fatal_exception 'oh noez, it was fatal!', e
      end

      expect(stdout_spy).to have_received(:error).with(/logger_with_sentry.*rb.*in `rescue in .*' An error was found. exception="fake error" sentry_event_id=.*/)
      expect(stdout_spy).to have_received(:fatal).with(/logger_with_sentry.*rb.*in `rescue in .*' oh noez, it was fatal! exception="fake error" sentry_event_id=.*/)
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

      expect(stdout_spy).to have_received(:info).with(/event=layer3 elapsed_time=\d+\.\d+/)
      expect(stdout_spy).to have_received(:info).with(/event=layer2 elapsed_time=\d+\.\d+/)
      expect(stdout_spy).to have_received(:info).with(/event=layer1 elapsed_time=\d+\.\d+/)
      expect(stdout_spy).to have_received(:error).with(having_number_of_lines_less_than(10))
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

      expect(stdout_spy).to have_received(:info).with('event="killer_block_party Blockless party"')
    end

    it 'logs events with attributes' do
      logger.event :killer_block_party, {time: '5pm', location: 'campus'}, 'Blockless party'

      expect(stdout_spy).to have_received(:info).with('event="killer_block_party Blockless party" time=5pm location=campus')
    end

    it 'logs events with blocks' do
      logger.event 'killer_block_party2', 'All summer strong' do
        logger.debug "I'm in a block!"
      end

      expect(stdout_spy).to have_received(:debug).with("I'm in a block!")
      expect(stdout_spy).to have_received(:info).with(/event=\"killer_block_party2 All summer strong\" elapsed_time=0.\d+/)
    end
  end
end
