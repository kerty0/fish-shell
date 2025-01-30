import re

from lldb import SBValue, SBError


def strip_ansi(val):
    return re.sub("\x1b[^m]*m\x0f?", "", val)


def read_string_8(data_ptr: SBValue, length: int) -> str:
    if data_ptr is None or length == 0:
        return '""'

    process = data_ptr.GetProcess()
    start = data_ptr.GetValueAsUnsigned()
    error = SBError()
    data = process.ReadMemory(start, length, error)
    string = strip_ansi(data.decode(encoding="UTF-8"))

    return f'"{string}"'


def read_string_32(data_ptr: SBValue, length: int) -> str:
    if data_ptr is None or length == 0:
        return '""'

    process = data_ptr.GetProcess()
    start = data_ptr.GetValueAsUnsigned()
    error = SBError()
    data = process.ReadMemory(start, length * 4, error)
    string = strip_ansi(data.decode(encoding="UTF-32"))

    return f'"{string}"'


def FishStrSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    data_ptr = valobj.GetChildMemberWithName("data_ptr")
    length = valobj.GetChildMemberWithName("length").GetValueAsUnsigned()
    return read_string_32(data_ptr, length)


def FishStringSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    vec = valobj.GetChildAtIndex(0).GetNonSyntheticValue()
    data_ptr = (
        vec.GetChildMemberWithName("buf")
        .GetChildMemberWithName("inner")
        .GetChildMemberWithName("ptr")
        .GetChildMemberWithName("pointer")
        .GetChildMemberWithName("pointer")
    )
    length = vec.GetChildMemberWithName("len").GetValueAsUnsigned()
    return read_string_32(data_ptr, length)


def FishCoordSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    x = valobj.GetChildMemberWithName("x").GetValueAsUnsigned()
    y = valobj.GetChildMemberWithName("y").GetValueAsUnsigned()
    return f"x={x} y={y}"


def FishTermsizeSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    x = valobj.GetChildMemberWithName("width").GetValueAsUnsigned()
    y = valobj.GetChildMemberWithName("height").GetValueAsUnsigned()
    return f"width={x} height={y}"


def FishHighlightedCharSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    offset: SBValue = valobj.GetChildMemberWithName("offset_in_cmdline")
    name = offset.GetTypeName()[26:]
    if name != "None":
        value = offset.GetChildAtIndex(0).GetValueAsUnsigned()
        name += f"({value})"
    char = chr(valobj.GetChildMemberWithName("character").GetValueAsUnsigned())
    return f"offset={name} char='{char}'"


def FishLineSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    indent = valobj.GetChildMemberWithName("indentation").GetValueAsUnsigned()
    text = valobj.GetChildMemberWithName("text")
    data = b"".join(
        text.GetChildAtIndex(i)
        .GetChildAtIndex(1)
        .GetValueAsUnsigned()
        .to_bytes(4, "little")
        for i in range(text.GetNumChildren())
    )
    string = strip_ansi(data.decode(encoding="UTF-32", errors="replace"))
    return f'indent={indent} text="{string}"'


def FishScreenDataSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    cursor = valobj.GetChildMemberWithName("cursor")
    x = cursor.GetChildMemberWithName("x").GetValueAsUnsigned()
    y = cursor.GetChildMemberWithName("y").GetValueAsUnsigned()
    lines = valobj.GetChildMemberWithName("line_datas")
    length = lines.GetNumChildren()
    lines = "\n".join(
        (l := FishLineSummaryProvider(lines.GetChildAtIndex(i)))[l.find('"') + 1 : -1]
        for i in range(length)
    )
    return f'x={x} y={y} len={length} text="\n{lines}\n"'


def FishEditSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    range = valobj.GetChildMemberWithName("range")
    start = range.GetChildMemberWithName("start").GetValueAsUnsigned()
    end = range.GetChildMemberWithName("end").GetValueAsUnsigned()
    old = FishStringSummaryProvider(valobj.GetChildMemberWithName("old"))
    new = FishStringSummaryProvider(valobj.GetChildMemberWithName("replacement"))
    return f"range={start}..{end} old={old} new={new}"


def FishEditableLineSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    pos = valobj.GetChildMemberWithName("position").GetValueAsUnsigned()
    text = valobj.GetChildMemberWithName("text")
    string = FishStringSummaryProvider(text)
    return f"pos={pos} text={string}"


def FishAutosuggestionSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    text = FishStringSummaryProvider(valobj.GetChildMemberWithName("text"))
    range = valobj.GetChildMemberWithName("search_string_range")
    start = range.GetChildMemberWithName("start").GetValueAsUnsigned()
    end = range.GetChildMemberWithName("end").GetValueAsUnsigned()
    return f"range={start}..{end} suggestion={text}"


def FishCompletionSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    comp = FishStringSummaryProvider(valobj.GetChildMemberWithName("completion"))
    decs = FishStringSummaryProvider(valobj.GetChildMemberWithName("description"))
    return f"comp={comp} decs={decs}"


def FishPagerCompSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    data = valobj.GetChildMemberWithName("representative")
    return FishCompletionSummaryProvider(data)


def FishHistoryItemSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    content = FishStringSummaryProvider(valobj.GetChildMemberWithName("contents"))
    return f"{content}"


def FishHistoryFileContentsSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    region = valobj.GetChildMemberWithName("region")
    string = read_string_8(
        region.GetChildMemberWithName("ptr"),
        region.GetChildMemberWithName("len").GetValueAsUnsigned(),
    )
    return f"{string}"


def FishHistorySummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    def get_file_item(start, length) -> str:
        data = process.ReadMemory(start, length, error)
        string = data.decode(encoding="UTF-8")
        return string[: string.find("\n")]

    data = (
        valobj.GetChildAtIndex(0)
        .GetChildMemberWithName("data")
        .GetChildMemberWithName("value")
    )

    file = (
        data.GetChildMemberWithName("file_contents")
        .GetChildAtIndex(0)
        .GetChildMemberWithName("region")
    )
    offsets = data.GetChildMemberWithName("old_item_offsets")
    offsets = [
        offsets.GetChildAtIndex(i).GetValueAsUnsigned()
        for i in range(offsets.GetNumChildren())
    ]
    offsets.append(file.GetChildMemberWithName("len").GetValueAsUnsigned())

    ptr = file.GetChildMemberWithName("ptr")
    process = ptr.GetProcess()
    error = SBError()
    start = ptr.GetValueAsUnsigned()

    items = []
    for i in range(len(offsets) - 1):
        items.append(
            get_file_item(start + offsets[i] + 7, offsets[i + 1] - offsets[i] - 8)
        )

    pending = data.GetChildMemberWithName("pending").GetValueAsUnsigned()
    new_items = data.GetChildMemberWithName("new_items")
    items.extend(
        FishHistoryItemSummaryProvider(new_items.GetChildAtIndex(i))
        for i in range(new_items.GetNumChildren())
        if not pending or i != 0
    )

    items.append(None)
    items.reverse()

    return f"size={len(items) - 1}\n" + "\n".join(
        f"[{i}]={item}" for i, item in enumerate(items)
    )


def FishSearchMatchSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    text = FishStringSummaryProvider(valobj.GetChildMemberWithName("text"))
    offset = valobj.GetChildMemberWithName("offset").GetValueAsUnsigned()
    return f"offset={offset} text={text}"


def FishHighlightSpecSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    fg = valobj.GetChildMemberWithName("foreground")
    bg = valobj.GetChildMemberWithName("background")
    return f"fg={fg.value} bg={bg.value}"


def FishSourceRangeSummaryProvider(valobj: SBValue, _dict: dict = None) -> str:
    start = valobj.GetChildMemberWithName("start").GetValueAsUnsigned()
    length = valobj.GetChildMemberWithName("length").GetValueAsUnsigned()
    return f"{start}..{start + length}"


FISH_TYPES = {
    "^(&|&mut |\\*const |\\*mut )widestring::utfstr::Utf32Str$": FishStrSummaryProvider,
    "^widestring::utfstring::Utf32String$": FishStringSummaryProvider,
    "^fish::key::ViewportPosition$": FishCoordSummaryProvider,
    "^fish::screen::Cursor$": FishCoordSummaryProvider,
    "^fish::screen::HighlightedChar$": FishHighlightedCharSummaryProvider,
    "^fish::screen::Line$": FishLineSummaryProvider,
    "^fish::screen::ScreenData$": FishScreenDataSummaryProvider,
    "^fish::editable_line::Edit$": FishEditSummaryProvider,
    "^fish::editable_line::EditableLine$": FishEditableLineSummaryProvider,
    "^fish::reader::Autosuggestion$": FishAutosuggestionSummaryProvider,
    "^fish::termsize::Termsize$": FishTermsizeSummaryProvider,
    "^fish::complete::Completion$": FishCompletionSummaryProvider,
    "^fish::pager::PagerComp$": FishPagerCompSummaryProvider,
    "^fish::history::HistoryItem$": FishHistoryItemSummaryProvider,
    "^fish::history::file::HistoryFileContents$": FishHistoryFileContentsSummaryProvider,
    "^fish::history::History$": FishHistorySummaryProvider,
    "^fish::reader_history_search::SearchMatch$": FishSearchMatchSummaryProvider,
    "^fish::highlight::highlight::HighlightSpec$": FishHighlightSpecSummaryProvider,
    "^fish::parse_constants::SourceRange": FishSourceRangeSummaryProvider,
}


def __lldb_init_module(debugger, _dict: dict):
    for regex, provider in FISH_TYPES.items():
        debugger.HandleCommand(
            f'type summary add -F lldb_fish.{provider.__name__} -e -x -h "{regex}" --category Fish'
        )
    debugger.HandleCommand("type category enable Fish")
    print("Fish types enabled!")
