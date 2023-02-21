load("cache.star", "cache")
load("encoding/base64.star", "base64")
load("encoding/json.star", "json")
load("http.star", "http")
load("random.star", "random")
load("render.star", "render")
load("schema.star", "schema")

QUOTE_FILE_VERSION = 1
QUOTE_FILE = "http://127.0.0.1:8088/quotes_v{}.json".format(str(QUOTE_FILE_VERSION))
PROD_QUOTE_FILE = "https://raw.githubusercontent.com/jchappell82/ct-quotes-tidbyt/main/quotes_v{}.json".format(str(QUOTE_FILE_VERSION))
BG_COLOR = "#222"
QUOTE_CACHE_KEY = "ct_quote_data_v{}".format(str(QUOTE_FILE_VERSION))
CACHE_TTL = 86400

# Set these two variables to override the character and/or quote index
# for easy debugging.
DEBUG_CHARACTER = "frog"
DEBUG_INDEX = 0
# DEBUG_CHARACTER = ""
# DEBUG_INDEX = None

def load_quotes():
    quotes = cache.get("ct_quote_data")

    if not quotes:
        req = http.get(PROD_QUOTE_FILE)
        if req.status_code != 200:
            print("Request failed: " + str(req.status_code))
            return {}

        quotes = req.body()
        cache.set(QUOTE_CACHE_KEY, quotes, ttl_seconds=CACHE_TTL)

    return json.decode(quotes)


def get_random_quote(quote_data):
    all_characters = list(quote_data["characters"].keys())

    character = all_characters[random.number(0, len(all_characters) - 1)]
    print("Selected " + character)
    if DEBUG_CHARACTER:
        print("Debug character override: " + DEBUG_CHARACTER)
        character = DEBUG_CHARACTER

    char_quotes = quote_data["characters"].get(DEBUG_CHARACTER, quote_data["characters"][character])

    idx = random.number(0, len(char_quotes) - 1)
    if DEBUG_INDEX != None:
        print("Debug quote index override: " + str(DEBUG_INDEX))
        idx = DEBUG_INDEX
    rand_quote = char_quotes[idx]

    return rand_quote


def main(config):
    quote_data = load_quotes()
    anim_speed = 150
    if quote_data:
        current_quote = get_random_quote(quote_data)
        img = current_quote["image"]
        children = [
            render.Image(src=base64.decode(img)),
            render.Marquee(
                height = 32,
                align = "center",
                offset_start = 15,
                offset_end = 32,
                child = render.WrappedText(
                    content = current_quote["text"],
                    align = current_quote.get("align", "left"),
                    width = current_quote.get("text_width", 45),
                    font = current_quote.get("font", "tb-8"),
                ),
                scroll_direction = "vertical",
            ),
        ]
        anim_speed = current_quote["speed"]
    else:
        children = [
            render.Marquee(
                height = 32,
                align = "left",
                child = render.WrappedText(
                    content = "Bummer! Unable to load quote data for version " + str(QUOTE_FILE_VERSION),
                    align = "left",
                    width = 45,
                ),
                scroll_direction = "vertical",
            )
        ]

    return render.Root(
        child = render.Box(
            color = BG_COLOR,
            child = render.Row(
                expanded = True,
                main_align = "space_evenly",
                cross_align = "center",
                children = children,
            ),
        ),
        delay = anim_speed,
        show_full_animation = True,
    )

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "ct-quotes",
                name = "Chrono Trigger Quotes",
                desc = "Displays random quotes from the SNES title \"Chrono Trigger\".",
                icon = "gamepad",
            ),
        ],
    )