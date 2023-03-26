#ifndef BLOOMTILE
#define BLOOMTILE

// Tile pattern based on algorithm from Null (original here: https://www.shadertoy.com/view/fl2cRD)

float getTilePos(float tile) {
    return 1.0 - exp2(-tile);
}

float getTileSize(float tile) {
    float tileMin = getTilePos(tile);
    float tileMax = getTilePos(tile + 1.0);
    return tileMax - tileMin;
}

void getTileOuterBounds(vec2 pixelSize, float tile, out vec2 minBounds, out vec2 maxBounds) {

    float xRefTile = floor(tile * 0.5) * 2.0;
    minBounds.x = (2.0 / 3.0) * (1.0 - exp2(-xRefTile) + xRefTile * pixelSize.x) + xRefTile * pixelSize.x;
    minBounds.y = fract(tile * 0.5) * (1.0 + 8.0 * pixelSize.y);
    // minBounds += 0.5 * pixelSize;

    float tileSize = getTileSize(tile);
    maxBounds = minBounds + tileSize + 2.0 * pixelSize;
}

void getTileInnerBounds(vec2 pixelSize, int tile, vec2 outerMinBounds, vec2 outerMaxBounds, out vec2 minBounds, out vec2 maxBounds) {
    vec2 center = 0.5 * (outerMinBounds + outerMaxBounds);

    minBounds = min(outerMinBounds + pixelSize, center);
    maxBounds = max(outerMaxBounds - pixelSize, center);
}

void getTileCoordStore(vec2 texcoord, vec2 pixelSize, int tileCount, out int tile, out vec2 samplecoord) {
    vec2 outerMinBounds, outerMaxBounds, innerMinBounds, innerMaxBounds;

    for(tile = 0; tile < tileCount; tile++) {
        getTileOuterBounds(pixelSize, float(tile), outerMinBounds, outerMaxBounds);

        if(texcoord.x > outerMinBounds.x && texcoord.x <= outerMaxBounds.x
            && texcoord.y > outerMinBounds.y && texcoord.y <= outerMaxBounds.y)
            break;
    }
    if(tile == tileCount) {
        tile = -1;
        return;
    }

    // innerMinBounds = outerMinBounds;
    // innerMaxBounds = outerMaxBounds;
    getTileInnerBounds(pixelSize, tile, outerMinBounds, outerMaxBounds, innerMinBounds, innerMaxBounds);

    samplecoord = (texcoord - innerMinBounds) / (innerMaxBounds - innerMinBounds);
}

vec4 getTileBoundsBlur(vec2 texcoord, vec2 pixelSize, int tileCount) {
    vec2 outerMinBounds, outerMaxBounds, innerMinBounds, innerMaxBounds;
    int tile;

    for(tile = 0; tile < tileCount; tile++) {
        getTileOuterBounds(pixelSize, float(tile), outerMinBounds, outerMaxBounds);

        if(texcoord.x > outerMinBounds.x && texcoord.x <= outerMaxBounds.x
            && texcoord.y > outerMinBounds.y && texcoord.y <= outerMaxBounds.y)
            break;
    }
    if(tile == tileCount) {
        return vec4(-1.0);
    }

    return vec4(outerMinBounds, outerMaxBounds);
}

vec2 getTileCoordRead(vec2 texcoord, vec2 pixelSize, int tile, out vec4 bounds) {
    vec2 outerMinBounds, outerMaxBounds, innerMinBounds, innerMaxBounds;

    getTileOuterBounds(pixelSize, float(tile), outerMinBounds, outerMaxBounds);
    getTileInnerBounds(pixelSize, tile, outerMinBounds, outerMaxBounds, innerMinBounds, innerMaxBounds);

    // if(clamp(texcoord, innerMinBounds, innerMaxBounds) != texcoord)
    //     return vec2(-1.0);

    bounds = vec4(innerMinBounds, innerMaxBounds);

    return texcoord * (innerMaxBounds - innerMinBounds) + innerMinBounds;
}

#endif