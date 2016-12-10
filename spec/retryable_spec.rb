describe 'retryable' do

  it 'should retry until successful' do
    x = 0
    ret = Woodsman.retryable {
      x += 1
      raise "Meh #{x}" if x < 3
      x
    }
    expect(ret).to eq(3)
  end

  it 'should fail if max retries is exceeded' do
    expect {
      x = 0
      ret = Woodsman.retryable {
        x += 1
        raise "Meh #{x}" if x < 10
        x
      }
    }.to raise_error(RuntimeError)
  end

  it 'should not retry if no failure' do
    x = 0
    ret = Woodsman.retryable {
      x += 1
    }
    expect(ret).to eq(1)
  end

  it 'should retry only up to max retries even with a retry lambda failing' do
    x = 0
    ret = Woodsman.retryable(max_retries: 3, retry_lambda: ->(a) { a < 5 }) {
      x += 1
    }
    expect(ret).to eq(4)
  end

  it 'should retry until the return passes' do
    x = 0
    ret = Woodsman.retryable(max_retries: 10, retry_lambda: ->(a) { a < 5 }) {
      x += 1
    }
    expect(ret).to eq(5)
  end

  it 'should have access to retry metadata while doing retry only up to max retries even with a retry lambda failing' do
    x = 0
    ret = Woodsman.retryable(max_retries: 3, retry_lambda: ->(a) { a < 5 }) { |rm|
      expect(rm[:try_number]).to eq(x+1)
      expect(rm[:error_count]).to eq(0)
      x += 1
    }
    expect(ret).to eq(4)
  end

  it 'should have access to retry metadata while doing retry until the return passes' do
    x = 0
    ret = Woodsman.retryable(max_retries: 10, retry_lambda: ->(a) { a < 5 }) { |rm|
      expect(rm[:try_number]).to eq(x+1)
      expect(rm[:error_count]).to eq(0)
      x += 1
    }
    expect(ret).to eq(5)
  end

  it 'should have access to retry metadata while doing fail if max retries is exceeded' do
    expect {
      x = 0
      ret = Woodsman.retryable { |rm|
        expect(rm[:try_number]).to eq(x+1)
        expect(rm[:error_count]).to eq(x)
        x += 1
        raise "Meh #{x}" if x < 10
        x
      }
    }.to raise_error(RuntimeError)
  end
end