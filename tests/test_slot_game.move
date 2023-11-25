#[test_only]
module slots::test_slot_game{
    use std::debug;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::test_scenario::{Self as tsc};
    use sui::object::{Self};

    use slots::test_common::{Self as tc};
    use slots::slot_game::{Self as sg};
    use slots::house_data::{Self as hd, HouseData};

    const EWrongPlayerBalanceAfterLoss: u64 = 1;
    const EWrongPlayerBalanceAfterWin: u64 = 2;
    const EWrongHouseFees: u64 = 3;
    const EWrongCoinBalance: u64 = 4;
    const EWrongHouseBalanceAfterWin: u64 = 5;
    const EWrongHouseBalanceAfterLoss: u64 = 6;

    #[test]
    fun house_win(){
        let owner = @0xCAFE;
        let player = @0xDECAf;

        let scenario_val = tsc::begin(owner);
        let scenario = &mut scenario_val;
        {
            tc::fund_addresses(scenario, owner, player, tc::get_initial_house_balance(), tc::get_initial_player_balance());
        };
        tc::init_house(scenario, owner, true);
        let game_id = tc::create_game(scenario, player, tc::get_min_stake(), false);

        tc::end_game(scenario, game_id, owner, player, false);

        tsc::next_tx(scenario, player);
        {
            let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
            let player_coin = tsc::take_from_sender<Coin<SUI>>(scenario);
            assert!(coin::value(&player_coin) == tc::get_initial_player_balance() - tc::get_min_stake(), EWrongPlayerBalanceAfterLoss);
            assert!(hd::balance(&house_data) == tc::get_initial_house_balance() + tc::get_min_stake(), EWrongHouseBalanceAfterWin);
            tsc::return_to_sender(scenario, player_coin);
            tsc::return_shared(house_data);
        };
        tsc::end(scenario_val);
    }

    #[test]
    fun player_win(){
        let owner = @0xCAFE;
        let player = @0xDECAf;

        let scenario_val = tsc::begin(owner);
        let scenario = &mut scenario_val;
        {
            tc::fund_addresses(scenario, owner, player, tc::get_initial_house_balance(), tc::get_initial_player_balance());
        };
        tc::init_house(scenario, owner, true);
        let game_id = tc::create_game(scenario, player, tc::get_min_stake(), true);
        let game_fees = tc::game_fees(scenario, game_id, owner);

        debug::print(&game_fees);

        tc::end_game(scenario, game_id, owner, player, true);
        

        tsc::next_tx(scenario, player);
        {
            let house_data = tsc::take_shared<HouseData<SUI>>(scenario);
            let player_coin = tsc::take_from_sender<Coin<SUI>>(scenario);
            assert!(hd::balance(&house_data) == tc::get_initial_house_balance() - tc::get_min_stake(), EWrongHouseBalanceAfterLoss);
            assert!(hd::fees(&house_data) == game_fees, EWrongHouseFees);
            assert!(coin::value(&player_coin) == tc::get_min_stake()*2 - game_fees, EWrongPlayerBalanceAfterWin);
            tsc::return_to_sender(scenario, player_coin);
            tsc::return_shared(house_data);
        };
        tsc::end(scenario_val);
    }
}