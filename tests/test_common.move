#[test_only]
module slots::test_common{
    // use std::string::{Self};
    use sui::address;

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::transfer;
    use sui::test_scenario::{Self as tsc, Scenario};
    use sui::object::ID;
    use sui::test_random::{Self, Random};

    use slots::house_data::{Self as hd, HouseCap, HouseData};
    use slots::slot_game::{Self as sg};

    const MIN_STAKE: u64 = 1_000_000_000; // 1 SUI
    // const MAX_STAKE: u64 = 50_000_000_000; // 50 SUI

    const INITIAL_HOUSE_BALANCE: u64 = 5_000_000_000; // 1 SUI
    // const INITIAL_PLAYER_BALANCE: u64 = 3_000_000_000; // 3 SUI

    const ROLL_NUMBER_ONE: u64 = 1;

        // House's public key.
    const PUBLIC_KEY: vector<u8> = vector<u8> [
        134, 225,   1, 158, 217, 213,  32,  70, 180,
        42, 251, 131,  44, 112, 114, 117, 186,  65,
        90, 223, 233, 110,  24, 254, 105, 205, 219,
        236,  49, 113,  59, 167, 137,  19, 119,  39,
        75, 146, 197, 214,  70, 164, 176, 221,  55,
        218,  63, 198
    ];

    public fun get_initial_house_balance(): u64 {
        return INITIAL_HOUSE_BALANCE
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
        stake: u64
    ): ID {
        tsc::next_tx(scenario, player);
        let player_coin = tsc::take_from_sender<Coin<SUI>>(scenario);
        let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
        let ctx = tsc::ctx(scenario);
        let stake_coin = coin::split(&mut player_coin, stake, ctx);
        let seed = address::to_bytes(player);

        let game_id = sg::new_game<SUI>(
            ROLL_NUMBER_ONE,
            ROLL_NUMBER_ONE,
            ROLL_NUMBER_ONE,
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
        let house_data = tsc::take_shared<HouseData<T>>(scenario);
        // let game = sg::
    }
}