"""Choose the coverage map's five colours by measurement, not by eye.

A DESIGN-TIME tool. It is not part of the build, is not copied into the
container image, and nothing imports it. Run it by hand when the map's
palette is in question, then paste the result into `COVERAGE_LEVELS` in
`build_site.py` — which is the single place the built stylesheet reads
its colours from.

Two shades that look obviously different in a list of swatches can be
nearly the same colour in fact: a deep red and a deep orange shipped side
by side on the map at ΔE 10, and read as one colour. So the scale is
searched rather than picked. Every combination of candidate shades is
scored on the perceptual distance between EVERY pair (CIEDE2000 — RGB
distance does not match what an eye reports), and rejected outright
unless each cell's label clears 4.5:1 against its own fill.

Colour is the only visual carrier of the count on this map, so the same
distances are measured again through simulations of the two common forms
of red-green colour blindness. A scale that separates cleanly for most
readers and collapses for the rest has not solved the problem.

    python3 scripts/choose_coverage_scale.py            # search
    python3 scripts/choose_coverage_scale.py '#7f1d1d' ...  # report on one
"""
import itertools

# The five families are fixed — the map's meaning lives in them. Only the
# shade within each family is up for selection.
CANDIDATES = {
    "not yet addressed": ["#ef4444", "#dc2626", "#b91c1c", "#991b1b", "#7f1d1d"],
    "addressed once": ["#fdba74", "#fb923c", "#f97316", "#ea580c", "#c2410c", "#9a3412"],
    "addressed twice": ["#fde047", "#fcd34d", "#facc15", "#fbbf24", "#eab308", "#f59e0b"],
    "three times": ["#4ade80", "#22c55e", "#16a34a", "#15803d", "#166534"],
    "four or more": ["#3b82f6", "#2563eb", "#1d4ed8", "#1e40af", "#1e3a8a", "#172554"],
}

WHITE = "#ffffff"
INK = "#1f2937"          # the dark label already used by the yellow step
MINIMUM_LABEL = 4.5      # WCAG AA for small text

# Machado, Oliveira & Fernandes (2009), severity 1.0, applied to LINEAR rgb.
DEUTERANOPIA = ((0.367322, 0.860646, -0.227968),
                (0.280085, 0.672501, 0.047413),
                (-0.011820, 0.042940, 0.968881))
PROTANOPIA = ((0.152286, 1.052583, -0.204868),
              (0.114503, 0.786281, 0.099216),
              (-0.003882, -0.048116, 1.051998))


def to_rgb(hex_colour):
    hex_colour = hex_colour.lstrip("#")
    result = []
    for index in (0, 2, 4):
        result.append(int(hex_colour[index:index + 2], 16) / 255)
    return result


def to_linear(channels):
    result = []
    for channel in channels:
        if channel <= 0.04045:
            result.append(channel / 12.92)
        else:
            result.append(((channel + 0.055) / 1.055) ** 2.4)
    return result


def relative_luminance(hex_colour):
    linear = to_linear(to_rgb(hex_colour))
    return 0.2126 * linear[0] + 0.7152 * linear[1] + 0.0722 * linear[2]


def contrast(one, other):
    first = relative_luminance(one)
    second = relative_luminance(other)
    if second > first:
        first, second = second, first
    return (first + 0.05) / (second + 0.05)


def best_label(hex_colour):
    """The label a cell would carry, and how well it reads."""
    on_white = contrast(hex_colour, WHITE)
    on_ink = contrast(hex_colour, INK)
    if on_white >= on_ink:
        return WHITE, on_white
    return INK, on_ink


def to_lab(hex_colour, linear=None):
    if linear is None:
        linear = to_linear(to_rgb(hex_colour))
    red, green, blue = linear
    x = 0.4124 * red + 0.3576 * green + 0.1805 * blue
    y = 0.2126 * red + 0.7152 * green + 0.0722 * blue
    z = 0.0193 * red + 0.1192 * green + 0.9505 * blue
    # D65 white point
    coordinates = [x / 0.95047, y / 1.00000, z / 1.08883]
    adjusted = []
    for value in coordinates:
        if value > 0.008856:
            adjusted.append(value ** (1 / 3))
        else:
            adjusted.append(7.787 * value + 16 / 116)
    lightness = 116 * adjusted[1] - 16
    return (lightness,
            500 * (adjusted[0] - adjusted[1]),
            200 * (adjusted[1] - adjusted[2]))


def simulate(hex_colour, matrix):
    """How a colour-blind reader sees this colour, as a Lab triple."""
    linear = to_linear(to_rgb(hex_colour))
    seen = []
    for row in matrix:
        value = row[0] * linear[0] + row[1] * linear[1] + row[2] * linear[2]
        seen.append(min(1.0, max(0.0, value)))
    return to_lab(None, linear=seen)


def delta_e(first, second):
    """CIEDE2000. RGB distance does not match what an eye reports."""
    import math
    lightness_1, a_1, b_1 = first
    lightness_2, a_2, b_2 = second
    chroma_1 = math.hypot(a_1, b_1)
    chroma_2 = math.hypot(a_2, b_2)
    mean_chroma = (chroma_1 + chroma_2) / 2
    g = 0.5 * (1 - math.sqrt(mean_chroma ** 7 / (mean_chroma ** 7 + 25 ** 7))) \
        if mean_chroma > 0 else 0
    a_prime_1 = (1 + g) * a_1
    a_prime_2 = (1 + g) * a_2
    chroma_prime_1 = math.hypot(a_prime_1, b_1)
    chroma_prime_2 = math.hypot(a_prime_2, b_2)
    hue_prime_1 = math.degrees(math.atan2(b_1, a_prime_1)) % 360
    hue_prime_2 = math.degrees(math.atan2(b_2, a_prime_2)) % 360

    delta_lightness = lightness_2 - lightness_1
    delta_chroma = chroma_prime_2 - chroma_prime_1
    if chroma_prime_1 * chroma_prime_2 == 0:
        delta_hue = 0
    else:
        difference = hue_prime_2 - hue_prime_1
        if difference > 180:
            difference -= 360
        elif difference < -180:
            difference += 360
        delta_hue = difference
    delta_hue_term = 0 if chroma_prime_1 * chroma_prime_2 == 0 else \
        2 * math.sqrt(chroma_prime_1 * chroma_prime_2) * math.sin(math.radians(delta_hue / 2))

    mean_lightness = (lightness_1 + lightness_2) / 2
    mean_chroma_prime = (chroma_prime_1 + chroma_prime_2) / 2
    if chroma_prime_1 * chroma_prime_2 == 0:
        mean_hue = hue_prime_1 + hue_prime_2
    else:
        difference = abs(hue_prime_1 - hue_prime_2)
        total = hue_prime_1 + hue_prime_2
        if difference <= 180:
            mean_hue = total / 2
        elif total < 360:
            mean_hue = (total + 360) / 2
        else:
            mean_hue = (total - 360) / 2

    t = (1
         - 0.17 * math.cos(math.radians(mean_hue - 30))
         + 0.24 * math.cos(math.radians(2 * mean_hue))
         + 0.32 * math.cos(math.radians(3 * mean_hue + 6))
         - 0.20 * math.cos(math.radians(4 * mean_hue - 63)))
    delta_theta = 30 * math.exp(-(((mean_hue - 275) / 25) ** 2))
    rotation = 2 * math.sqrt(mean_chroma_prime ** 7 /
                             (mean_chroma_prime ** 7 + 25 ** 7)) \
        if mean_chroma_prime > 0 else 0
    lightness_weight = 1 + (0.015 * (mean_lightness - 50) ** 2) / \
        math.sqrt(20 + (mean_lightness - 50) ** 2)
    chroma_weight = 1 + 0.045 * mean_chroma_prime
    hue_weight = 1 + 0.015 * mean_chroma_prime * t
    rotation_term = -math.sin(math.radians(2 * delta_theta)) * rotation

    return math.sqrt(
        (delta_lightness / lightness_weight) ** 2
        + (delta_chroma / chroma_weight) ** 2
        + (delta_hue_term / hue_weight) ** 2
        + rotation_term * (delta_chroma / chroma_weight) * (delta_hue_term / hue_weight))


def worst_pair(colours, matrix=None):
    """The closest two colours in a scale, and how far apart they are."""
    if matrix is None:
        labs = [to_lab(colour) for colour in colours]
    else:
        labs = [simulate(colour, matrix) for colour in colours]
    worst = None
    for first, second in itertools.combinations(range(len(colours)), 2):
        distance = delta_e(labs[first], labs[second])
        if worst is None or distance < worst[0]:
            worst = (distance, first, second)
    return worst


def search():
    names = list(CANDIDATES)
    best = []
    for combination in itertools.product(*(CANDIDATES[name] for name in names)):
        labels = []
        acceptable = True
        for colour in combination:
            label, ratio = best_label(colour)
            if ratio < MINIMUM_LABEL:
                acceptable = False
                break
            labels.append((label, ratio))
        if not acceptable:
            continue
        normal = worst_pair(combination)
        deuteran = worst_pair(combination, DEUTERANOPIA)
        protan = worst_pair(combination, PROTANOPIA)
        # Score on the weakest separation any reader would face.
        score = min(normal[0], deuteran[0], protan[0])
        best.append((score, normal, deuteran, protan, combination, labels))
    best.sort(key=lambda entry: entry[0], reverse=True)
    return names, best


def report(scale):
    """Everything worth knowing about one proposed scale."""
    names = list(CANDIDATES)
    light_panel, dark_panel = "#e5e5e5", "#393639"
    print(" ".join(scale))
    print("\n label, hovered label, and the panel each step sits on:")
    for index, colour in enumerate(scale):
        label, ratio = best_label(colour)
        hovered = hover_wash(colour)
        print(f"   {names[index]:<20} {colour}  "
              f"{'white' if label == WHITE else 'ink  '} {ratio:5.2f}:1  "
              f"hovered {contrast(hovered, label):5.2f}:1  "
              f"panel light {contrast(colour, light_panel):4.2f} "
              f"dark {contrast(colour, dark_panel):4.2f}")
    for title, matrix in (("ordinary vision", None),
                          ("deuteranopia", DEUTERANOPIA),
                          ("protanopia", PROTANOPIA)):
        distance, first, second = worst_pair(scale, matrix)
        print(f" {title:<16} closest pair: {names[first]} / {names[second]} "
              f"ΔE {distance:.1f}")


def hover_wash(hex_colour, alpha=0.12):
    """The cell as it appears while hovered — white laid over the fill."""
    channels = []
    for index in (0, 2, 4):
        value = int(hex_colour.lstrip("#")[index:index + 2], 16)
        channels.append(round(value * (1 - alpha) + 255 * alpha))
    result = "#"
    for channel in channels:
        result += f"{channel:02x}"
    return result


def search_and_report(floor=11.0, shown=6):
    """The scales worth looking at, best ordinary-vision separation first.

    Ranking by the weakest case alone returns near-identical scales that
    differ only in one step, which hides the real choices — so scales are
    grouped by their first four steps, and a floor is applied to what a
    colour-blind reader sees rather than optimising for that case only.
    """
    names = list(CANDIDATES)
    leaders = {}
    for combination in itertools.product(*(CANDIDATES[name] for name in names)):
        labels = []
        for colour in combination:
            labels.append(best_label(colour))
        if min(ratio for _, ratio in labels) < MINIMUM_LABEL:
            continue
        normal = worst_pair(combination)
        deuteran = worst_pair(combination, DEUTERANOPIA)
        protan = worst_pair(combination, PROTANOPIA)
        if deuteran[0] < floor or protan[0] < floor:
            continue
        key = combination[:4]
        if key not in leaders or normal[0] > leaders[key][0]:
            leaders[key] = (normal[0], deuteran[0], protan[0], combination)
    ranked = sorted(leaders.values(), key=lambda entry: entry[0], reverse=True)
    print(f"{len(ranked)} distinct scales clear 4.5:1 on every label and "
          f"ΔE {floor} for colour-blind readers\n")
    for normal_score, deuteran_score, protan_score, combination in ranked[:shown]:
        print(f" {' '.join(combination)}")
        print(f"   ordinary ΔE {normal_score:5.1f}   deuteranopia "
              f"{deuteran_score:4.1f}   protanopia {protan_score:4.1f}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        report(sys.argv[1:])
    else:
        search_and_report()
        print("\nwhat build_site.py ships today:")
        report(["#7f1d1d", "#f97316", "#facc15", "#15803d", "#1e3a8a"])
