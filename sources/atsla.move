module 0x0::step1_coin {
    use sui::coin::{Self, TreasuryCap, CoinMetadata, Coin};
    use sui::tx_context::{Self, TxContext};
    use sui::url::Url;
    use std::option;
    use sui::transfer;
    use sui::event;

    /// One-time witness for coin creation
    public struct STEP1_COIN has drop {}

    /// Event emitted when tokens are minted
    public struct MintEvent has copy, drop {
        recipient: address,
        amount: u64,
    }

    /// Event emitted when tokens are burned
    public struct BurnEvent has copy, drop {
        amount: u64,
    }

    /// Initializes the coin with metadata and transfers the TreasuryCap to the publisher
    fun init(_w: STEP1_COIN, ctx: &mut TxContext) {
        let (tcap, metadata): (TreasuryCap<STEP1_COIN>, CoinMetadata<STEP1_COIN>) =
            coin::create_currency<STEP1_COIN>(
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

        // Freeze the metadata
        transfer::public_freeze_object(metadata);
    }

    /// Mint new tokens using the TreasuryCap
    public entry fun mint(
        treasury_cap: &mut TreasuryCap<STEP1_COIN>,
        recipient: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        let coin = coin::mint(treasury_cap, amount, ctx);
        
        // Emit mint event
        event::emit(MintEvent {
            recipient,
            amount,
        });
        
        transfer::public_transfer(coin, recipient);
    }

    /// Mint tokens and return the coin (for testing and composability)
    public fun mint_and_return(
        treasury_cap: &mut TreasuryCap<STEP1_COIN>,
        amount: u64,
        ctx: &mut TxContext
    ): Coin<STEP1_COIN> {
        let coin = coin::mint(treasury_cap, amount, ctx);
        
        // Emit mint event
        event::emit(MintEvent {
            recipient: tx_context::sender(ctx),
            amount,
        });
        
        coin
    }

    /// Burn tokens
    public entry fun burn(
        treasury_cap: &mut TreasuryCap<STEP1_COIN>,
        coin: Coin<STEP1_COIN>
    ) {
        let amount = coin::value(&coin);
        coin::burn(treasury_cap, coin);
        
        // Emit burn event
        event::emit(BurnEvent {
            amount,
        });
    }

    /// Get total supply
    public fun total_supply(treasury_cap: &TreasuryCap<STEP1_COIN>): u64 {
        coin::total_supply(treasury_cap)
    }

    /// Get coin value
    public fun value(coin: &Coin<STEP1_COIN>): u64 {
        coin::value(coin)
    }

    // ===== Test Functions =====

    #[test_only]
    public fun test_create_coin(ctx: &mut TxContext): TreasuryCap<STEP1_COIN> {
        let (tcap, metadata) = coin::create_currency<STEP1_COIN>(
            STEP1_COIN {},
            18,
            b"aTSLA",
            b"Tesla Allo Stock",
            b"A mintable and burnable token representing Tesla exposure",
            option::none<Url>(),
            ctx
        );

        transfer::public_freeze_object(metadata);
        tcap
    }

    #[test_only]
    public fun test_init(ctx: &mut TxContext) {
        init(STEP1_COIN {}, ctx);
    }
}