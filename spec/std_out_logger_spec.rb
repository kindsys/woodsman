describe 'StdOutLogger' do

  it 'should only log error and above by default' do
    stdout = Woodsman::StdOutLogger.new

    expect(stdout).to receive(:puts).with('e')
    expect(stdout).to receive(:puts).with('f')

    stdout.debug('d')
    stdout.info('i')
    stdout.error('e')
    stdout.fatal('f')

    expect(stdout.log_level).to eq(Woodsman::LOG_LEVEL_ERROR)
  end

  it 'should honor the config for debug level output' do
    stdout = Woodsman::StdOutLogger.new(Woodsman::LOG_LEVEL_DEBUG)

    expect(stdout).to receive(:puts).with('d')
    expect(stdout).to receive(:puts).with('i')
    expect(stdout).to receive(:puts).with('e')
    expect(stdout).to receive(:puts).with('f')

    stdout.debug('d')
    stdout.info('i')
    stdout.error('e')
    stdout.fatal('f')

    expect(stdout.log_level).to eql(Woodsman::LOG_LEVEL_DEBUG)
  end

  it 'should honor the config for info level output' do
    stdout = Woodsman::StdOutLogger.new(Woodsman::LOG_LEVEL_INFO)

    expect(stdout).to receive(:puts).with('i')
    expect(stdout).to receive(:puts).with('e')
    expect(stdout).to receive(:puts).with('f')

    stdout.debug('d')
    stdout.info('i')
    stdout.error('e')
    stdout.fatal('f')

    expect(stdout.log_level).to eql(Woodsman::LOG_LEVEL_INFO)
  end

  it 'should honor the config for error level output' do
    stdout = Woodsman::StdOutLogger.new(Woodsman::LOG_LEVEL_ERROR)

    expect(stdout).to receive(:puts).with('e')
    expect(stdout).to receive(:puts).with('f')

    stdout.debug('d')
    stdout.info('i')
    stdout.error('e')
    stdout.fatal('f')

    expect(stdout.log_level).to eql(Woodsman::LOG_LEVEL_ERROR)
  end

  it 'should honor the config for fatal level output' do
    stdout = Woodsman::StdOutLogger.new(Woodsman::LOG_LEVEL_FATAL)

    expect(stdout).to receive(:puts).with('f')

    stdout.debug('d')
    stdout.info('i')
    stdout.error('e')
    stdout.fatal('f')

    expect(stdout.log_level).to eql(Woodsman::LOG_LEVEL_FATAL)
  end
end