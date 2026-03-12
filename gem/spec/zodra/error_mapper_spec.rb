# frozen_string_literal: true

RSpec.describe Zodra::ErrorMapper do
  let(:mapper_class) do
    Class.new(described_class) do
      def call(order:, payment: nil)
        collect(order) do
          map :name
          map :email
          map 'address.street' => :street
          map 'address.city' => :city
        end

        if payment
          collect(payment) do
            map :card_number
            map expiry: :card_expiry
          end
        end

        assert_no_unmapped!
        result
      end
    end
  end

  describe '.call' do
    it 'maps direct keys from a hash source' do
      errors = mapper_class.call(
        order: { name: ['is required'], email: ['is invalid'] }
      )

      expect(errors).to eq(
        name: ['is required'],
        email: ['is invalid']
      )
    end

    it 'maps nested dot-notation keys' do
      errors = mapper_class.call(
        order: { 'address.street' => ['is required'], 'address.city' => ['is required'] }
      )

      expect(errors).to eq(
        street: ['is required'],
        city: ['is required']
      )
    end

    it 'collects errors from multiple sources' do
      errors = mapper_class.call(
        order: { name: ['is required'] },
        payment: { card_number: ['is invalid'], expiry: ['has expired'] }
      )

      expect(errors).to eq(
        name: ['is required'],
        card_number: ['is invalid'],
        card_expiry: ['has expired']
      )
    end

    it 'extracts errors from AR-like objects' do
      record = double('Record', errors: double('Errors', to_hash: { name: ['is required'] }))

      errors = mapper_class.call(order: record)

      expect(errors).to eq(name: ['is required'])
    end

    it 'skips keys not present in source' do
      errors = mapper_class.call(order: { name: ['is required'] })

      expect(errors).to eq(name: ['is required'])
      expect(errors).not_to have_key(:email)
    end

    it 'wraps scalar error messages in arrays' do
      errors = mapper_class.call(order: { name: 'is required' })

      expect(errors).to eq(name: ['is required'])
    end

    it 'normalizes symbol and string keys in source' do
      errors = mapper_class.call(
        order: { 'name' => ['string key'], email: ['symbol key'] }
      )

      expect(errors).to eq(
        name: ['string key'],
        email: ['symbol key']
      )
    end
  end

  describe 'assert_no_unmapped!' do
    it 'raises UnmappedErrorsError when source has unmapped keys' do
      extra_mapper = Class.new(described_class) do
        def call(record:)
          collect(record) do
            map :name
          end
          assert_no_unmapped!
          result
        end
      end

      expect do
        extra_mapper.call(record: { name: ['ok'], unknown_field: ['surprise'] })
      end.to raise_error(Zodra::ErrorMapper::UnmappedErrorsError, /unknown_field/)
    end

    it 'does not raise when all keys are mapped' do
      expect do
        mapper_class.call(order: { name: ['ok'], email: ['ok'] })
      end.not_to raise_error
    end

    it 'does not raise when source has no errors' do
      expect do
        mapper_class.call(order: {})
      end.not_to raise_error
    end
  end

  describe 'map outside collect block' do
    it 'raises an error' do
      bad_mapper = Class.new(described_class) do
        def call
          map :name
          result
        end
      end

      expect do
        bad_mapper.call
      end.to raise_error(Zodra::Error, /map must be called inside a collect block/)
    end
  end

  describe 'merging errors from multiple sources to same key' do
    it 'concatenates error messages' do
      merge_mapper = Class.new(described_class) do
        def call(source_a:, source_b:)
          collect(source_a) do
            map :name
          end
          collect(source_b) do
            map display_name: :name
          end
          assert_no_unmapped!
          result
        end
      end

      errors = merge_mapper.call(
        source_a: { name: ['is required'] },
        source_b: { display_name: ['is too short'] }
      )

      expect(errors).to eq(name: ['is required', 'is too short'])
    end
  end

  describe 'without call implementation' do
    it 'raises NotImplementedError' do
      bare_mapper = Class.new(described_class)

      expect do
        bare_mapper.call
      end.to raise_error(NotImplementedError, /call must be implemented/)
    end
  end

  describe '#add' do
    it 'adds a message directly to result without a source' do
      precondition_mapper = Class.new(described_class) do
        def call(locked:)
          add :base, "Can't be modified because week is locked" if locked
          result
        end
      end

      errors = precondition_mapper.call(locked: true)
      expect(errors).to eq(base: ["Can't be modified because week is locked"])
    end

    it 'appends to existing messages on the same key' do
      multi_add_mapper = Class.new(described_class) do
        def call
          add :base, 'Error one'
          add :base, 'Error two'
          result
        end
      end

      errors = multi_add_mapper.call
      expect(errors).to eq(base: ['Error one', 'Error two'])
    end
  end

  describe '#consume' do
    it 'marks a key as handled without mapping it' do
      consume_mapper = Class.new(described_class) do
        def call(record:)
          collect(record) do
            map :name
            consume :internal_field
          end
          assert_no_unmapped!
          result
        end
      end

      errors = consume_mapper.call(record: { name: ['ok'], internal_field: ['ignored'] })
      expect(errors).to eq(name: ['ok'])
    end

    it 'raises when called outside collect block' do
      bad_mapper = Class.new(described_class) do
        def call
          consume :name
          result
        end
      end

      expect do
        bad_mapper.call
      end.to raise_error(Zodra::Error, /consume must be called inside a collect block/)
    end
  end

  describe '#source_errors' do
    it 'provides access to raw source errors for inspection' do
      rewrite_mapper = Class.new(described_class) do
        def call(record:)
          collect(record) do
            if source_errors['items'] == ["can't be blank"]
              consume :items
              add :base, 'Items must exist'
            else
              map :items
            end
            map :name
          end
          assert_no_unmapped!
          result
        end
      end

      errors = rewrite_mapper.call(record: { name: ['ok'], items: ["can't be blank"] })
      expect(errors).to eq(name: ['ok'], base: ['Items must exist'])
    end

    it 'raises when called outside collect block' do
      bad_mapper = Class.new(described_class) do
        def call
          source_errors
        end
      end

      expect do
        bad_mapper.call
      end.to raise_error(Zodra::Error, /source_errors must be called inside a collect block/)
    end
  end

  describe 'complex scenario: precondition + consume + rewrite + nested' do
    it 'handles all patterns together' do
      complex_mapper = Class.new(described_class) do
        def call(checklist:, items:, locked: false)
          add :base, 'Week is locked' if locked

          collect(checklist) do
            if source_errors['check_list_items'] == ["can't be blank"]
              consume :check_list_items
              add :base, 'Checklist items must exist'
            end
            map :name
          end

          result[:items] = items.map do |item|
            item.errors.any? ? item.errors.to_hash : nil
          end

          assert_no_unmapped!
          result
        end
      end

      item_ok = double('Item', errors: double(any?: false, to_hash: {}))
      item_bad = double('Item', errors: double(any?: true, to_hash: { text: ['is required'] }))

      errors = complex_mapper.call(
        checklist: { name: ['is required'], check_list_items: ["can't be blank"] },
        items: [item_ok, item_bad],
        locked: true
      )

      expect(errors[:base]).to eq(['Week is locked', 'Checklist items must exist'])
      expect(errors[:name]).to eq(['is required'])
      expect(errors[:items]).to eq([nil, { text: ['is required'] }])
    end
  end

  describe '#ignore' do
    it 'marks multiple keys as handled without mapping' do
      ignore_mapper = Class.new(described_class) do
        def call(record:)
          collect(record) do
            map :name
            ignore :password_digest, :confirmation_token, :lock_version
          end
          assert_no_unmapped!
          result
        end
      end

      errors = ignore_mapper.call(
        record: { name: ['ok'], password_digest: ['err'], confirmation_token: ['err'], lock_version: ['err'] }
      )

      expect(errors).to eq(name: ['ok'])
    end

    it 'raises when called outside collect block' do
      bad_mapper = Class.new(described_class) do
        def call
          ignore :name
          result
        end
      end

      expect do
        bad_mapper.call
      end.to raise_error(Zodra::Error, /ignore must be called inside a collect block/)
    end
  end

  describe '#map_remaining' do
    it 'maps all unconsumed keys 1:1' do
      remaining_mapper = Class.new(described_class) do
        def call(record:)
          collect(record) do
            map internal_name: :name
            ignore :lock_version
            map_remaining
          end
          assert_no_unmapped!
          result
        end
      end

      errors = remaining_mapper.call(
        record: { internal_name: ['too short'], lock_version: ['stale'], email: ['invalid'], age: ['too young'] }
      )

      expect(errors).to eq(name: ['too short'], email: ['invalid'], age: ['too young'])
    end

    it 'works with empty remaining keys' do
      all_mapped = Class.new(described_class) do
        def call(record:)
          collect(record) do
            map :name
            map_remaining
          end
          assert_no_unmapped!
          result
        end
      end

      errors = all_mapped.call(record: { name: ['ok'] })
      expect(errors).to eq(name: ['ok'])
    end

    it 'raises when called outside collect block' do
      bad_mapper = Class.new(described_class) do
        def call
          map_remaining
          result
        end
      end

      expect do
        bad_mapper.call
      end.to raise_error(Zodra::Error, /map_remaining must be called inside a collect block/)
    end
  end

  describe 'invalid source' do
    it 'raises ArgumentError for unsupported types' do
      bad_source_mapper = Class.new(described_class) do
        def call(source:)
          collect(source) do
            map :name
          end
          result
        end
      end

      expect do
        bad_source_mapper.call(source: 'not a hash or record')
      end.to raise_error(ArgumentError, /Expected a Hash/)
    end
  end
end
