#[test_only]
module slots::test_common{
    // use std::string::{Self};

    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    // use sui::transfer;
    use sui::test_scenario::{Self as tsc, Scenario};
    // use sui::object::ID;

    use slots::house_data::{Self as hd, HouseCap};

    const INITIAL_HOUSE_BALANCE: u64 = 5_000_000_000; // 1 SUI
    // const INITIAL_PLAYER_BALANCE: u64 = 3_000_000_000; // 3 SUI

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
}