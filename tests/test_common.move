#[test_only]
module slots::test_common{
    // use std::string::{Self};
    use std::debug;
    use std::vector;

    use sui::address;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::test_scenario::{Self as tsc, Scenario};
    use sui::object::ID;

    use slots::house_data::{Self as hd, HouseCap, HouseData};
    use slots::slot_game::{Self as sg};
    use slots::roll;

    const MIN_STAKE: u64 = 1_000_000_000; // 1 SUI
    // const MAX_STAKE: u64 = 50_000_000_000; // 50 SUI

    const INITIAL_HOUSE_BALANCE: u64 = 5_000_000_000; // 1 SUI
    const INITIAL_PLAYER_BALANCE: u64 = 3_000_000_000; // 3 SUI

    const ROLL_NUMBER_ZERO: u8 = 0;
    const ROLL_NUMBER_ONE: u8 = 1;
    const ROLL_NUMBER_TWO: u8 = 2;
    const ROLL_NUMBER_THREE: u8 = 3;

    // House's public key.
    const PUBLIC_KEY: vector<u8> = vector<u8> [
        134, 225,   1, 158, 217, 213,  32,  70, 180,
        42, 251, 131,  44, 112, 114, 117, 186,  65,
        90, 223, 233, 110,  24, 254, 105, 205, 219,
        236,  49, 113,  59, 167, 137,  19, 119,  39,
        75, 146, 197, 214,  70, 164, 176, 221,  55,
        218,  63, 198
    ];

    const INVALID_BLS_SIG: vector<u8> = vector<u8>[
        129, 108, 254,  61, 148, 134, 105, 218, 212,  49, 136, 118,
        224, 223, 148,  83, 245, 230, 113, 248,  33, 169, 169,  78,
        108,  67, 144, 229, 243,  47, 248, 249, 172, 175, 181,  15,
        213, 223, 198,  85,  69,  15,  81, 234, 141, 240, 196,  88,
        3, 152,  64, 226, 101, 248, 157, 192, 180,  77, 156, 209,
        233,  93, 106,  87, 205,  90,  97, 181, 218,   6, 108, 246,
        17,  39, 197, 223,  36,  36,  86, 143, 130, 147, 212, 213,
        184,  38, 252, 169,  20,  58, 226, 180, 174, 222,  57, 171
    ];

    public fun get_initial_house_balance(): u64 {
        return INITIAL_HOUSE_BALANCE
    }

    public fun get_initial_player_balance(): u64 {
        INITIAL_PLAYER_BALANCE
    }

    public fun get_min_stake(): u64 {
        MIN_STAKE
    }

    public fun init_house(scenario: &mut Scenario, owner: address, valid_coin: bool){
        tsc::next_tx(scenario, owner);
        {
            let ctx = tsc::ctx(scenario);
            hd::init_for_testing(ctx);
        };

        tsc::next_tx(scenario, owner);
        {
            let house_cap = tsc::take_from_sender<HouseCap>(scenario);

            if(valid_coin){
                let coin = tsc::take_from_sender<Coin<SUI>>(scenario);
                let ctx = tsc::ctx(scenario);
                
                hd::initialize_house_data(
                    house_cap, 
                    owner, 
                    PUBLIC_KEY,
                    coin,
                    ctx
                )
            }else{
                let ctx = tsc::ctx(scenario);
                let zero_coin = coin::zero<SUI>(ctx);
                hd::initialize_house_data(
                    house_cap, 
                    owner, 
                    PUBLIC_KEY,
                    zero_coin,
                    ctx
                )
            }
        }
    }

    public fun fund_addresses(
        scenario: &mut Scenario, 
        house: address, 
        player: address, 
        house_funds: u64,
        player_funds: u64
    ){
        let ctx = tsc::ctx(scenario);
        let coinA = coin::mint_for_testing<SUI>(house_funds, ctx);
        let coinB = coin::mint_for_testing<SUI>(player_funds, ctx);
        transfer::public_transfer(coinA, house);
        transfer::public_transfer(coinB, player);
    }

    public fun create_game(
        scenario: &mut Scenario,
        player: address,
        stake: u64,
        player_won: bool,
    ): ID {
        tsc::next_tx(scenario, player);
        let player_coin = tsc::take_from_sender<Coin<SUI>>(scenario);
        let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
        let ctx = tsc::ctx(scenario);
        let stake_coin = coin::split(&mut player_coin, stake, ctx);
        let seed = address::to_bytes(player);

        let result_roll_one = if (player_won){ROLL_NUMBER_ZERO} else {ROLL_NUMBER_ONE};
        let result_roll_two = if (player_won){ROLL_NUMBER_ONE} else {ROLL_NUMBER_TWO};
        let result_roll_three = if (player_won){ROLL_NUMBER_ONE} else {ROLL_NUMBER_THREE};
        let roll_guess = vector::empty<u8>();
        vector::push_back(&mut roll_guess, result_roll_one);
        vector::push_back(&mut roll_guess, result_roll_two);
        vector::push_back(&mut roll_guess, result_roll_three);
        let game_id = sg::new_game<SUI>(
            roll_guess,
            seed,
            &mut house_data,
            stake_coin,
            ctx
        );
        tsc::return_shared(house_data);
        tsc::return_to_sender(scenario, player_coin);
        return game_id
    }

    public fun game_fees(scenario: &mut Scenario, game_id: ID, owner: address): u64 {
        tsc::next_tx(scenario, owner);
        let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
        let game = sg::borrow_game(game_id, &mut house_data);
        let stake_mount = sg::stake_amount<SUI>(game);
        let fee_rate = sg::fee_rate<SUI>(game);
        let (_, multiple_number) = roll::roll_player(sg::roll_guess<SUI>(game));
        let fees_amount = sg::fee_amount(stake_mount, fee_rate, multiple_number);
        tsc::return_shared(house_data);
        return fees_amount
    }

    public fun submit_roll_guess(scenario: &mut Scenario, game_id: ID, player: address){
        tsc::next_tx(scenario, player);
        {
            let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
            let ctx = tsc::ctx(scenario);
            sg::summit_guess<SUI>(game_id, &mut house_data, ctx);
            tsc::return_shared(house_data);
        }
    }

    public fun end_game(scenario: &mut Scenario, game_id: ID, owner: address, player: address, valid_sig: bool) {
        tsc::next_tx(scenario, owner);
        {
            let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
            let ctx = tsc::ctx(scenario);
            let idx: u64 = 0;
            let bls_sig = address::to_bytes(address::from_u256(address::to_u256(player) - (idx as u256)));
            let signature = if(valid_sig) {bls_sig} else {INVALID_BLS_SIG};
            sg::finish_game<SUI>(game_id, &mut house_data, signature, true, ctx);

            tsc::return_shared(house_data);
        }
    }

    public fun advance_epochs(scenario: &mut Scenario, sender: address, epochs: u64){
        tsc::next_tx(scenario, sender);
        {
            let number_epoch=0;
            while(number_epoch < epochs){
                tsc::next_epoch(scenario, sender);
                number_epoch = number_epoch + 1;
            }
        }
    }
}