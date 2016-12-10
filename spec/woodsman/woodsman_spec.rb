describe Woodsman do
  describe '.truthy?' do
    context 'when falsey val is provided' do
      it 'returns false' do
        expect(Woodsman.truthy?(nil)).to be false
      end

      it 'returns false' do
        expect(Woodsman.truthy?(false)).to be false
      end

      it 'returns false' do
        expect(Woodsman.truthy?('false')).to be false
      end

      it 'returns false' do
        expect(Woodsman.truthy?('f')).to be false
      end

      it 'returns false' do
        expect(Woodsman.truthy?(0)).to be false
      end

      it 'returns false' do
        expect(Woodsman.truthy?('n')).to be false
      end

      it 'returns false' do
        expect(Woodsman.truthy?('no')).to be false
      end
    end

    context 'when truthy val is provided' do
      it 'returns true' do
        expect(Woodsman.truthy?(true)).to be true
      end

      it 'returns true' do
        expect(Woodsman.truthy?('y')).to be true
      end

      it 'returns true' do
        expect(Woodsman.truthy?('yes')).to be true
      end

      it 'returns true' do
        expect(Woodsman.truthy?(1)).to be true
      end

      it 'returns true' do
        expect(Woodsman.truthy?('true')).to be true
      end

      it 'returns true' do
        expect(Woodsman.truthy?('t')).to be true
      end
    end
  end

  describe '.valid_uid?' do
    let(:val) { nil }
    subject { Woodsman.valid_uid?(val) }

    context 'when nil' do
      let(:val) { nil }
      it { is_expected.to be false }
    end

    context 'when an invalid string' do
      let(:val) { 'invalid' }
      it { is_expected.to be false }
    end

    context 'when an empty string' do
      let(:val) { '' }
      it { is_expected.to be false }
    end

    context 'when a valid UUID' do
      let(:val) { SecureRandom.uuid.to_s }
      it { is_expected.to be true }
    end
  end
end
