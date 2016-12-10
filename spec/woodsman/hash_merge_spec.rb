describe 'Hash Merge' do

  let(:h1) { nil }
  let(:h2) { nil }
  subject(:h) { Woodsman.merge_hash(h1, h2) }

  context 'when first hash is nil' do
    context 'when second hash is nil' do
      it { is_expected.to eq({}) }
    end

    context 'when second hash is empty' do
      let(:h2) { Hash.new }

      it { is_expected.to eq({}) }
    end

    context 'when second hash is flat' do
      let(:h2) { {a: 1, "c" => 3, e: "world"} }

      it { is_expected.to eq({a: 1, "c" => 3, e: "world"}) }
    end

    context 'when second hash has an array value' do
      let(:h2) { {a1: [{x: 100, z: 300}, {x: 101, z: 303}]} }

      it { is_expected.to eq({a1: [{x: 100, z: 300}, {x: 101, z: 303}]}) }
    end

    context 'when second hash is deeply nested hash' do
      let(:h2) { {l1: {l2: {a: 1, b: 2, c: 3}}} }

      it { is_expected.to eq({l1: {l2: {a: 1, b: 2, c: 3}}}) }
    end

    context 'when second hash is complex' do

      let(:h2) { {l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1'} }

      it { is_expected.to eq({l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1'}) }
    end
  end

  context 'when first hash is empty' do
    let(:h1) { Hash.new }

    context 'when second hash is nil' do
      it { is_expected.to eq({}) }
    end

    context 'when second hash is empty' do
      let(:h2) { Hash.new }

      it { is_expected.to eq({}) }
    end

    context 'when second hash is flat' do
      let(:h2) { {a: 1, "c" => 3, e: "world"} }

      it { is_expected.to eq({a: 1, "c" => 3, e: "world"}) }
    end

    context 'when second hash has an array value' do
      let(:h2) { {a1: [{x: 100, z: 300}, {x: 101, z: 303}]} }

      it { is_expected.to eq({a1: [{x: 100, z: 300}, {x: 101, z: 303}]}) }
    end

    context 'when second hash is deeply nested hash' do
      let(:h2) { {l1: {l2: {a: 1, b: 2, c: 3}}} }

      it { is_expected.to eq({l1: {l2: {a: 1, b: 2, c: 3}}}) }
    end

    context 'when second hash is complex' do

      let(:h2) { {l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1'} }

      it { is_expected.to eq({l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1'}) }
    end
  end

  context 'when first hash is flat' do
    let(:h1) { {b: 2, d: "hello"} }

    context 'when second hash is nil' do
      it { is_expected.to eq({b: 2, d: "hello"}) }
    end

    context 'when second hash is empty' do
      let(:h2) { Hash.new }

      it { is_expected.to eq({b: 2, d: "hello"}) }
    end

    context 'when second hash is flat' do
      let(:h2) { {a: 1, "c" => 3, e: "world"} }

      it { is_expected.to eq({a: 1, b: 2, "c" => 3, d: "hello", e: "world"}) }
    end

    context 'when second hash has an array value' do
      let(:h2) { {a1: [{x: 100, z: 300}, {x: 101, z: 303}]} }

      it { is_expected.to eq({a1: [{x: 100, z: 300}, {x: 101, z: 303}], b: 2, d: "hello"}) }
    end

    context 'when second hash is deeply nested hash' do
      let(:h2) { {l1: {l2: {a: 1, b: 2, c: 3}}} }

      it { is_expected.to eq({l1: {l2: {a: 1, b: 2, c: 3}}, b: 2, d: "hello"}) }
    end

    context 'when second hash is complex' do

      let(:h2) { {l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1'} }

      it { is_expected.to eq({l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1', b: 2, d: "hello"}) }
    end
  end

  context 'when first hash has an array value' do
    let(:h1) { {a1: [{y: 200}, {y: 202}]} }

    context 'when second hash is nil' do
      it { is_expected.to eq({a1: [{y: 200}, {y: 202}]}) }
    end

    context 'when second hash is empty' do
      let(:h2) { Hash.new }

      it { is_expected.to eq({a1: [{y: 200}, {y: 202}]}) }
    end

    context 'when second hash is flat' do
      let(:h2) { {a: 1, "c" => 3, e: "world"} }

      it { is_expected.to eq({a1: [{y: 200}, {y: 202}], a: 1, "c" => 3, e: "world"}) }
    end

    context 'when second hash has an array value' do
      let(:h2) { {a1: [{x: 100, z: 300}, {x: 101, z: 303}]} }

      it { is_expected.to eq({a1: [{x: 100, y: 200, z: 300}, {x: 101, y: 202, z: 303}]}) }
    end

    context 'when second hash is deeply nested hash' do
      let(:h2) { {l1: {l2: {a: 1, b: 2, c: 3}}} }

      it { is_expected.to eq({l1: {l2: {a: 1, b: 2, c: 3}}, a1: [{y: 200}, {y: 202}]}) }
    end

    context 'when second hash is complex' do

      let(:h2) { {l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1'} }

      it { is_expected.to eq({l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2b: {a: [2, 4, 6], b: 'world'}}, k1: 'v1', a1: [{y: 200}, {y: 202}]}) }
    end
  end

  context 'when first hash s deeply nested hash' do
    let(:h1) { {l1: {l2: {e: 4, f: 5}, l2b: 'hi'}, k1: 1} }

    context 'when second hash is nil' do
      it { is_expected.to eq({l1: {l2: {e: 4, f: 5}, l2b: 'hi'}, k1: 1}) }
    end

    context 'when second hash is empty' do
      let(:h2) { Hash.new }

      it { is_expected.to eq({l1: {l2: {e: 4, f: 5}, l2b: 'hi'}, k1: 1}) }
    end

    context 'when second hash is flat' do
      let(:h2) { {a: 1, "c" => 3, e: "world"} }

      it { is_expected.to eq({l1: {l2: {e: 4, f: 5}, l2b: 'hi'}, k1: 1, a: 1, "c" => 3, e: "world"}) }
    end

    context 'when second hash has an array value' do
      let(:h2) { {a1: [{x: 100, z: 300}, {x: 101, z: 303}]} }

      it { is_expected.to eq({l1: {l2: {e: 4, f: 5}, l2b: 'hi'}, k1: 1, a1: [{x: 100, z: 300}, {x: 101, z: 303}]}) }
    end

    context 'when second hash is deeply nested hash' do
      let(:h2) { {l1: {l2: {a: 1, b: 2, c: 3}}} }

      it { is_expected.to eq({l1: {l2: {a: 1, b: 2, c: 3, e: 4, f: 5}, l2b: 'hi'}, k1: 1}) }
    end

    context 'when second hash is complex' do

      let(:h2) { {l1: {l2: {a: [1, 2, 3], b: 'hello'}, l2a: {a: [2, 4, 6], b: 'world'}}, k2: 'v2'} }

      it { is_expected.to eq({l1: {l2: {a: [1, 2, 3], b: 'hello', e: 4, f: 5}, l2a: {a: [2, 4, 6], b: 'world'}, l2b: 'hi'}, k1: 1, k2: 'v2'}) }
    end
  end

  context 'when conflicting keys' do

    let(:h1) { {a: 1, b: 2, c: 'test', l2: {a: 2, b: 'hello', c: [{a: 'a', c: 'c'}, {a: 'a2', c: 'c2'}]}, x: nil, y: 'team', z: '', z2: ''} }
    let(:h2) { {a: 2, c: 'prod', d: 4, l2: {a: 'x', b: 'world', c: [{a: 'x', b: 'y', c: 'z'}, {a: 'x2', b: 'y2'}]}, x: 'good', y: nil, z: 'ye', z2: nil} }

    it { is_expected.to eq({a: 2, b: 2, c: 'prod', d: 4, l2: {a: 'x', b: 'world', c: [{a: 'x', b: 'y', c: 'z'}, {a: 'x2', b: 'y2', c: 'c2'}]}, x: 'good', y: 'team', z: 'ye', z2: ''}) }
  end

  context 'when h1 has a nil value for merge' do
    let(:h1) { {a: nil, b: 2, l1: nil, a1: nil} }
    let(:h2) { {a: 'a', b: 'b', c: 'c', l1: {x: 1, y: 2}, a1: [1, 2]} }

    it { is_expected.to eq({a: 'a', b: 'b', c: 'c', l1: {x: 1, y: 2}, a1: [1, 2]}) }
  end

  context 'when h2 has a nil value for merge' do
    let(:h1) { {a: 'a', b: 'b', c: 'c', l1: {x: 1, y: 2}, a1: [1, 2]} }
    let(:h2) { {a: nil, b: 2, l1: nil, a1: nil} }

    it { is_expected.to eq({a: 'a', b: 2, c: 'c', l1: {x: 1, y: 2}, a1: [1, 2]}) }
  end

  context 'when there is a complex original source JSON that can be decomposed into secure and insecure parts' do

    let!(:original_json) { <<-EOS.freeze
{
        "balances": {
                "credit_cards": 50000,
                "installment_loans": 0
        },
        "accounts": {
                "credit_cards": [
                        {
                                "subscriber_name": "CAPITAL ONE",
                                "type": "Credit Card",
                                "balance": 100,
                                "monthly_payment": 100,
                                "is_open": true,
                                "account_number": "123412341000",
                                "account_type": "BC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "CAPITAL ONE",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ",
                                "monthly_payment_count": 0,
                                "credit_limit": 3000,
                                "high_credit": 4850,
                                "date_effective": "2016-01-01",
                                "date_opened": "2007-01-01"
                        },
                        {
                                "subscriber_name": "CAPITAL ONE",
                                "type": "Credit Card",
                                "balance": 500,
                                "monthly_payment": 131,
                                "is_open": true,
                                "account_number": "123412341001",
                                "account_type": "FX",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "CAPITAL ONE",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ2",
                                "monthly_payment_count": 0,
                                "credit_limit": 7500,
                                "high_credit": 7485,
                                "date_effective": "2016-02-01",
                                "date_opened": "2011-01-01"
                        },
                        {
                                "subscriber_name": "DISCOVERBANK",
                                "type": "Credit Card",
                                "balance": 300,
                                "monthly_payment": 63,
                                "is_open": true,
                                "account_number": "123412341002",
                                "account_type": "CC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "DISCOVERBANK",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ3",
                                "monthly_payment_count": 0,
                                "credit_limit": 3200,
                                "high_credit": 3215,
                                "date_effective": "2016-01-01",
                                "date_opened": "2015-01-01"
                        },
                        {
                                "subscriber_name": "PNC BANK",
                                "type": "Credit Card",
                                "balance": 14795,
                                "monthly_payment": 369,
                                "is_open": true,
                                "account_number": "123412341003",
                                "account_type": "FX",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "PNC BANK",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ4",
                                "monthly_payment_count": 0,
                                "credit_limit": 17500,
                                "high_credit": 17634,
                                "date_effective": "2016-02-01",
                                "date_opened": "2011-01-01"
                        },
                        {
                                "subscriber_name": "SYNCB/AMAZON",
                                "type": "Credit Card",
                                "balance": 2000,
                                "monthly_payment": 74,
                                "is_open": true,
                                "account_number": "123412341005",
                                "account_type": "CH",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "SYNCB/AMAZON",
                                "subscriber_industry_code": "D",
                                "subscriber_member_code": "XYZ5",
                                "monthly_payment_count": 0,
                                "credit_limit": 5400,
                                "high_credit": 2383,
                                "date_effective": "2016-02-01",
                                "date_opened": "2013-12-25"
                        },
                        {
                                "subscriber_name": "CHASE",
                                "type": "Credit Card",
                                "balance": 1337,
                                "monthly_payment": 40,
                                "is_open": true,
                                "account_number": "123412341006",
                                "account_type": "CC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "CHASE",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ6",
                                "monthly_payment_count": 0,
                                "credit_limit": 1500,
                                "high_credit": 1503,
                                "date_effective": "2016-02-01",
                                "date_opened": "2013-01-01"
                        },
                        {
                                "subscriber_name": "1 FBSD",
                                "type": "Credit Card",
                                "balance": 12000,
                                "monthly_payment": 333,
                                "is_open": true,
                                "account_number": "123412341007",
                                "account_type": "CC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "1 XYZ",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ7",
                                "monthly_payment_count": 0,
                                "credit_limit": 14000,
                                "high_credit": 12531,
                                "date_effective": "2016-01-01",
                                "date_opened": "2005-01-01"
                        }
                ],
                "installment_loans": [
                ]
        }
}
    EOS
    }
    let!(:original_hash) { JSON.parse(original_json).with_indifferent_access }

    let!(:insecure_json) { <<-EOS.freeze
{
        "balances": {
                "credit_cards": 50000,
                "installment_loans": 0
        },
        "accounts": {
                "credit_cards": [
                        {
                                "subscriber_name": "CAPITAL ONE",
                                "type": "Credit Card",
                                "balance": 100,
                                "monthly_payment": 100,
                                "is_open": true,
                                "account_type": "BC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "CAPITAL ONE",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ",
                                "monthly_payment_count": 0,
                                "credit_limit": 3000,
                                "high_credit": 4850,
                                "date_effective": "2016-01-01",
                                "date_opened": "2007-01-01"
                        },
                        {
                                "subscriber_name": "CAPITAL ONE",
                                "type": "Credit Card",
                                "balance": 500,
                                "monthly_payment": 131,
                                "is_open": true,
                                "account_type": "FX",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "CAPITAL ONE",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ2",
                                "monthly_payment_count": 0,
                                "credit_limit": 7500,
                                "high_credit": 7485,
                                "date_effective": "2016-02-01",
                                "date_opened": "2011-01-01"
                        },
                        {
                                "subscriber_name": "DISCOVERBANK",
                                "type": "Credit Card",
                                "balance": 300,
                                "monthly_payment": 63,
                                "is_open": true,
                                "account_type": "CC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "DISCOVERBANK",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ3",
                                "monthly_payment_count": 0,
                                "credit_limit": 3200,
                                "high_credit": 3215,
                                "date_effective": "2016-01-01",
                                "date_opened": "2015-01-01"
                        },
                        {
                                "subscriber_name": "PNC BANK",
                                "type": "Credit Card",
                                "balance": 14795,
                                "monthly_payment": 369,
                                "is_open": true,
                                "account_type": "FX",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "PNC BANK",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ4",
                                "monthly_payment_count": 0,
                                "credit_limit": 17500,
                                "high_credit": 17634,
                                "date_effective": "2016-02-01",
                                "date_opened": "2011-01-01"
                        },
                        {
                                "subscriber_name": "SYNCB/AMAZON",
                                "type": "Credit Card",
                                "balance": 2000,
                                "monthly_payment": 74,
                                "is_open": true,
                                "account_type": "CH",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "SYNCB/AMAZON",
                                "subscriber_industry_code": "D",
                                "subscriber_member_code": "XYZ5",
                                "monthly_payment_count": 0,
                                "credit_limit": 5400,
                                "high_credit": 2383,
                                "date_effective": "2016-02-01",
                                "date_opened": "2013-12-25"
                        },
                        {
                                "subscriber_name": "CHASE",
                                "type": "Credit Card",
                                "balance": 1337,
                                "monthly_payment": 40,
                                "is_open": true,
                                "account_type": "CC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "CHASE",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ6",
                                "monthly_payment_count": 0,
                                "credit_limit": 1500,
                                "high_credit": 1503,
                                "date_effective": "2016-02-01",
                                "date_opened": "2013-01-01"
                        },
                        {
                                "subscriber_name": "1 FBSD",
                                "type": "Credit Card",
                                "balance": 12000,
                                "monthly_payment": 333,
                                "is_open": true,
                                "account_type": "CC",
                                "portfolio_type": "revolving",
                                "account_rating_code": "01",
                                "account_rating": "Good",
                                "subscriber_name_unparsed": "1 XYZ",
                                "subscriber_industry_code": "B",
                                "subscriber_member_code": "XYZ7",
                                "monthly_payment_count": 0,
                                "credit_limit": 14000,
                                "high_credit": 12531,
                                "date_effective": "2016-01-01",
                                "date_opened": "2005-01-01"
                        }
                ],
                "installment_loans": [
                ]
        }
}
    EOS
    }
    let!(:insecure_hash) { JSON.parse(insecure_json).with_indifferent_access }

    let!(:secure_json) { <<-EOS.freeze
{
        "accounts": {
                "credit_cards": [
                        {
                                "account_number": "123412341000"
                        },
                        {
                                "account_number": "123412341001"
                        },
                        {
                                "account_number": "123412341002"
                        },
                        {
                                "account_number": "123412341003"
                        },
                        {
                                "account_number": "123412341005"
                        },
                        {
                                "account_number": "123412341006"
                        },
                        {
                                "account_number": "123412341007"
                        }
                ]
        }
}
    EOS
    }
    let!(:secure_hash) { JSON.parse(secure_json).with_indifferent_access }

    it 'splits out desired keys' do
      extract = {accounts: {credit_cards: [{account_number: true}]}}
      secure, insecure = Woodsman.split_hash(original_hash, extract)

      expect(secure).to eq(secure_hash)
      expect(insecure).to eq(insecure_hash)
    end

    it 'splits normal values' do
      h1 = {a: 'hi', b: 'ok'}
      extract = {a: true}

      secure, insecure = Woodsman.split_hash(h1, extract)

      expect(secure).to eq({a: 'hi'}.with_indifferent_access)
      expect(insecure).to eq({b: 'ok'}.with_indifferent_access)
    end

    it 'splits hash values' do
      h1 = {l1: {a: 'hi', b: 'ok'}}
      extract = {l1: {a: true}}

      secure, insecure = Woodsman.split_hash(h1, extract)

      expect(secure).to eq({l1: {a: 'hi'}}.with_indifferent_access)
      expect(insecure).to eq({l1: {b: 'ok'}}.with_indifferent_access)
    end

    it 'splits array values' do
      h1 = {a1: [{x: 1, y: 1}, {x: 2, y: 2}]}
      extract = {a1: [{x: 1}]}

      secure, insecure = Woodsman.split_hash(h1, extract)

      expect(secure).to eq({a1: [{x: 1}, {x: 2}]}.with_indifferent_access)
      expect(insecure).to eq({a1: [{y: 1}, {y: 2}]}.with_indifferent_access)
    end

    context 'when merging secure and insecure data' do

      it 'merges correctly' do
        merged_result = Woodsman.merge_hash(insecure_hash, secure_hash)

        expect(merged_result).to eq(original_hash)
      end
    end

    context 'when dealing with the lead data_hash' do
      let(:data_hash_string) { File.read('spec/examples/dh1.txt') }
      let(:data_hash) { JSON.parse(data_hash_string) }

      # TODO: write an xpath like merge syntax, maybe a :* =>
      it 'splits out secure data properly' do
        extract = {
            ip_address: 1,
            first_name: 1,
            last_name: 1,
            street_address1: 1,
            phone_number_primary: 1,
            email: 1,
            bureau_date_of_birth: 1,
            bureau_social_security_number: 1,
            normalized_street_address1: 1,
            funding_loan_external_id: {borrower_name: 1},
            social_security_number: 1,
            phone_number_secondary: 1,
            bank_account_routing_number: 1,
            bank_account_number: 1,
            bank_account_holder_name: 1,
            borrower_signature: 1,
            promissory_signature: 1,
            credit_policies: {
                credit_policy_V3: {
                    applicant: {
                        credit_report_subset: {
                            trades: [
                                {account_number: 1}]
                        }
                    }
                }
            },
            applicant: {
                credit_report_subset: {
                    trades: [
                        {account_number: 1}]
                }
            }
        }
# TODO: revisit. pretty sure these don't need to be secure
# user_friendly_id: true, woodsman_user_slug: true,

        secure, insecure = Woodsman.split_hash(data_hash, extract)

        expect(secure).to be
        expect(insecure).to be
        expect(insecure.to_s).not_to include('account_number')
        expect(insecure.to_s).not_to include('first_name')
        expect(insecure.to_s).not_to include('last_name')
        expect(insecure.to_s).not_to include('phone_number_primary')
        expect(insecure.to_s).not_to include('ip_address')
        expect(insecure.to_s).not_to include('address1')

# Put it back together again
        restored = Woodsman.merge_hash(secure, insecure)

        expect(restored).to eq(data_hash)
      end
    end
  end
end
