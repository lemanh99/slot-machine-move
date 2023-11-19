module slots::house_data{
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::package::{Self};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};

    // Error codes
    const ECallerNotHouse: u64 = 0;
    const EInsufficientBalance: u64 = 1;

    struct HouseData<phantom T> has key {
        id: UID,
        house_address: address,
        public_key: vector<u8>,
        balance: Balance<T>,
        fees: Balance<T>,
        fee_rate: u128,
        min_stake_amount: u64,
        max_stake_amount: u64
    }

    struct HouseCap has key {
        id: UID
    }

    struct HOUSE_DATA has drop {}

    // --------------- Constructor ---------------
    fun init(otw: HOUSE_DATA, ctx: &mut TxContext) {
        // Creating and sending the Publisher object to the sender.
        package::claim_and_keep(otw, ctx);

        // // Creating and sending the HouseCap object to the sender.
        let house_cap = HouseCap {
            id: object::new(ctx)
        };

        transfer::transfer(house_cap, tx_context::sender(ctx));
    }

    public fun initialize_house_data<T>(
        house_cap: HouseCap, 
        house_address: address, 
        public_key: vector<u8>,
        coin: Coin<T>,
    ){
        assert!(coin::value(&coin) > 0, EInsufficientBalance);

        let house_data = HouseData {
            id: object::new(ctx),
            house_address,
            public_key,
            balance: coin::into_balance(coin),
            fees: balance::zero(),
            fee_rate: 1, // 1% in basis points.
            min_stake_amount: 1_000_000_000, // 1 SUI.,
            max_stake_amount: 50_000_000_000, // 50 SUI, 1 SUI = 10^9.
        }
        let HouseCap { id } = house_cap;
        object::delete(id);

        transfer::share_object(house_data); 
    }

    public fun balance(house_data: &HouseData): u64 {
        house_data.balance
    }

    public fun min_stake_amount(house_data: &HouseData): u64 {
        house_data.min_stake_amount
    }
    public fun fees(house_data: &HouseData): u64{
        balance::value(&house_data.balance)
    }

    public fun fee_rate(house_data: &HouseData): u128{
        house_data.fee_rate
    }

    public fun max_stake_amount(house_data: &HouseData): u64 {
        house_data.max_stake_amount
    }

    public fun house_address(house_data: &HouseData): address {
        house_data.house_address
    }

    public fun public_key(house_data: &HouseData): vector<u8> {
        house_data.public_key
    }

}