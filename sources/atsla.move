module tesla_token::step1_coin {
    use sui::coin::{Self, TreasuryCap, CoinMetadata};
    use sui::tx_context::{Self, TxContext};
    use sui::object::{Self, UID};
    use sui::url::{Self, Url};
    use std::option;
    use sui::transfer;

    /// Witness for the coin
    public struct STEP1_COIN has drop {}

    fun init(_w: STEP1_COIN, ctx: &mut TxContext) {
        let (tcap, metadata): (TreasuryCap<STEP1_COIN>, CoinMetadata<STEP1_COIN>) = coin::create_currency<STEP1_COIN>(
            _w,
            18, // decimals
            b"aTSLA",
            b"Tesla Allo Stock",
            b"A mintable and burnable token representing Tesla exposure",
            option::none<Url>(),
            ctx
        );

        // Transfer TreasuryCap to publisher
        transfer::public_transfer(tcap, tx_context::sender(ctx));
        transfer::public_transfer(metadata, tx_context::sender(ctx));
    }
}
