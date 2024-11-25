module rgb::grid;

use std::string::{String};
use std::u64::{Self};

use sui::bcs::{Self};
use sui::display::{Self};
use sui::hex::{Self};
use sui::package::{Self};
use sui::random::{Random};

use codec::base64::{Self};

public struct GRID has drop {}

public struct Grid has key {
    id: UID,
    number: u64,
    size: u64,
    data_url: String,
}

public struct GridRegistry has key {
    id: UID,
    count: u64,
}

const MAX_GRID_SIZE: u64 = 1024;

const EMaxGridSizeExceeded: u64 = 0;
const ENonSquareGridSize: u64 = 1;

fun init(
    otw: GRID,
    ctx: &mut TxContext,
) {
    let publisher = package::claim(otw, ctx);

    let mut display = display::new<Grid>(&publisher, ctx);
    display.add(b"name".to_string(), b"RGB #{number}".to_string());
    display.add(b"description".to_string(), b"A {size}-pixel square, simple yet endlessly expressive.".to_string());
    display.add(b"number".to_string(), b"{number}".to_string());
    display.add(b"image_url".to_string(), b"{data_url}".to_string());
    display.update_version();

    let registry = GridRegistry {
        id: object::new(ctx),
        count: 0,
    };

    transfer::public_transfer(publisher, ctx.sender());
    transfer::public_transfer(display, ctx.sender());

    transfer::share_object(registry);
}

entry fun new(
    size: u64,
    registry: &mut GridRegistry,
    random: &Random,
    ctx: &mut TxContext,
) {
    assert!(size <= MAX_GRID_SIZE, EMaxGridSizeExceeded);

    let width = u64::sqrt(size);
    
    assert!(width * width == size, ENonSquareGridSize);

    let mut rg = random.new_generator(ctx);
    
    let mut svg = b"<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 ";
    let width_bytes = width.to_string().into_bytes();
    svg.append(width_bytes);
    svg.append(b" ");
    svg.append(width_bytes);
    svg.append(b"' style='width: 100vw; height: 100vh; image-rendering: pixelated; shape-rendering: crispEdges;' preserveAspectRatio='xMidYMid meet'><style>rect { width: 1px; height: 1px; }</style>");

    let mut y = 0;

    while (y < width) {
        svg.append(b"<g transform='translate(0, ");
        svg.append(y.to_string().into_bytes());
        svg.append(b")'>");

        let mut x = 0;
        while (x < width) {
            let n = rg.generate_u32(); 

            let hex_code = rgb_to_hex(
                (n & 0xFF) as u8,
                ((n >> 8) & 0xFF) as u8,
                ((n >> 16) & 0xFF) as u8,
            );

            svg.append(b"<rect x='");
            svg.append(x.to_string().into_bytes());
            svg.append(b"' fill='#");
            svg.append(hex_code);
            svg.append(b"'/>");

            x = x + 1;
        };
        svg.append(b"</g>");

        y = y + 1;
    };

    svg.append(b"</svg>");
    
    let mut data_url = b"data:image/svg+xml;base64,".to_string();
    data_url.append(base64::encode(svg));

    let grid = Grid {
        id: object::new(ctx),
        number: registry.count + 1,
        size: size,
        data_url: data_url,
    };

    registry.count = registry.count + 1;

    transfer::transfer(grid, ctx.sender());
}

fun rgb_to_hex(
    r: u8,
    g: u8,
    b: u8,
): vector<u8> {
    let mut hex = b"";
    hex.append(hex::encode(bcs::to_bytes(&r)));
    hex.append(hex::encode(bcs::to_bytes(&g)));
    hex.append(hex::encode(bcs::to_bytes(&b)));
    hex
}