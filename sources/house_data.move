module slots::house_data{
    use sui::object::{Self, UID};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin::{Self, Coin};
    use sui::package::{Self};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer::{Self};
    use sui::event::emit;


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

    struct HouseDataDeposit<phantom T> has copy, store, drop {
        amount: u64
    }

    struct HouseDataWithdraw<phantom T> has copy, store, drop {
        amount: u64
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

    // -------------------- Function -------------------------

    // event emit deposit
    public(friend) fun emit_house_data_deposit<T>(amount: u64) {
        emit(HouseDataDeposit<T> {
            amount,
        });
    }

    // event emit withdraw
    public(friend) fun emit_house_data_withdraw<T>(amount: u64) {
        emit(HouseDataWithdraw<T>{
            amount,
        });
    }

    /// Initializer function that should only be called once and by the creator of the contract.
    /// Initializes the house data object with the house's public key and an initial balance.
    /// It also sets the max and min stake values, that can later on be updated.
    /// Stores the house address and the base fee in basis points.
    /// This object is involed in all games created by the same instance of this package.
    public fun initialize_house_data<T>(
        house_cap: HouseCap, 
        house_address: address, 
        public_key: vector<u8>,
        coin: Coin<T>,
        ctx: &mut TxContext
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
            max_stake_amount: 50_000_000_000 // 50 SUI, 1 SUI = 10^9.
        };
        let HouseCap { id } = house_cap;
        object::delete(id);

        transfer::share_object(house_data); 
    }

    /// Function used to top up the house balance. Can be called by anyone.
    /// House can have multiple accounts so giving the treasury balance is not limited.
    public fun top_up<T>(house_data: &mut HouseData<T>, coin: Coin<T>, _: &mut TxContext){
        let coin_value = coin::value(&coin);
        let coin_balance = coin::into_balance(coin);
        emit_house_data_deposit<T>(coin_value);
        balance::join(&mut house_data.balance, coin_balance);
    }

     /// House can withdraw the entire balance of the house object.
    /// Caution should be taken when calling this function. 
    /// If all funds are withdrawn, it will result in the house not being able to participate in any more games.
    public fun withdraw<T>(house_data: &mut HouseData<T>, ctx: &mut TxContext){
        let house_address = house_address<T>(house_data);
        assert!(tx_context::sender(ctx)==house_address, ECallerNotHouse);

        let total_balance = balance<T>(house_data);
        emit_house_data_withdraw<T>(total_balance);
        let coin = coin::take(&mut house_data.balance, total_balance, ctx);
        transfer::public_transfer(coin, house_address);
    }

        /// House can withdraw the accumulated fees of the house object.
    public fun claim_fees<T>(house_data: &mut HouseData<T>, ctx: &mut TxContext) {
        // Only the house address can withdraw fee funds.
        let house_address = house_address<T>(house_data);
        assert!(tx_context::sender(ctx) == house_address, ECallerNotHouse);

        let total_fees = fees(house_data);
        let coin = coin::take(&mut house_data.fees, total_fees, ctx);
        transfer::public_transfer(coin, house_address);
    }

    /// House can update the max stake. This allows larger stake to be placed.
    public fun update_max_stake_amount<T>(house_data: &mut HouseData<T>, max_stake_amount: u64, ctx: &mut TxContext) {
        // Only the house address can update the base fee.
        assert!(tx_context::sender(ctx) == house_address<T>(house_data), ECallerNotHouse);

        house_data.max_stake_amount = max_stake_amount;
    }

    /// House can update the min stake. This allows smaller stake to be placed.
    public fun update_min_stake_amount<T>(house_data: &mut HouseData<T>, min_stake_amount: u64, ctx: &mut TxContext) {
        // Only the house address can update the min stake.
        assert!(tx_context::sender(ctx) == house_address<T>(house_data), ECallerNotHouse);

        house_data.min_stake_amount = min_stake_amount;
    }

    
    public fun house_address<T>(house_data: &HouseData<T>): address {
        house_data.house_address
    }
    
    public fun public_key<T>(house_data: &HouseData<T>): vector<u8> {
        house_data.public_key
    }

    public fun balance<T>(house_data: &HouseData<T>): u64 {
        balance::value(&house_data.balance)
    }
    
    public fun fees<T>(house_data: &HouseData<T>): u64 {
        balance::value(&house_data.fees)
    }

    public fun fee_rate<T>(house_data: &HouseData<T>): u128 {
        house_data.fee_rate
    }

    public fun min_stake_amount<T>(house_data: &HouseData<T>): u64 {
        house_data.min_stake_amount
    }

    public fun max_stake_amount<T>(house_data: &HouseData<T>): u64 {
        house_data.max_stake_amount
    }
}