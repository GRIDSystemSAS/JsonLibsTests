unit VSoft.YAML.TagInfo;

interface

{$I 'VSoft.YAML.inc'}

uses
  System.SysUtils,
  VSoft.YAML;

type
  // Base implementation of tag information
  TYAMLTagInfo = class(TInterfacedObject, IYAMLTagInfo)
  private
    FTagType: TYAMLTagType;
    FOriginalText: string;
    FResolvedTag: string;
    FHandle: string;
    FSuffix: string;
    FPrefix: string;
  protected
    function GetTagType: TYAMLTagType; virtual;
    function GetOriginalText: string; virtual;
    function GetResolvedTag: string; virtual;
    function GetHandle: string; virtual;
    function GetSuffix: string; virtual;
    function GetPrefix: string; virtual;
  public
    constructor Create(ATagType: TYAMLTagType; const AOriginalText, AResolvedTag: string;
      const AHandle: string = ''; const ASuffix: string = ''; const APrefix: string = '');
    
    function IsStandardTag: boolean; virtual;
    function IsGlobalTag: boolean; virtual;
    function IsLocalTag: boolean; virtual;
    function IsCustomTag: boolean; virtual;
    function IsVerbatimTag: boolean; virtual;
    function IsUnresolved: boolean; virtual;
    function AreEqual(const other: IYAMLTagInfo): boolean; overload;
    function ToString: string; override;
    
    property TagType: TYAMLTagType read GetTagType;
    property OriginalText: string read GetOriginalText;
    property ResolvedTag: string read GetResolvedTag;
    property Handle: string read GetHandle;
    property Suffix: string read GetSuffix;
    property Prefix: string read GetPrefix;
  end;

  // Factory class for creating tag info objects
  TYAMLTagInfoFactory = class
  public
    // Create tag info from raw tag text and resolved URI
    class function CreateFromText(const tagText: string; const resolvedURI: string = ''): IYAMLTagInfo;
    
    // Create standard YAML tags
    class function CreateStandardTag(const tagName: string): IYAMLTagInfo;
    
    // Create local tag
    class function CreateLocalTag(const tagName: string): IYAMLTagInfo;
    
    // Create custom tag with handle
    class function CreateCustomTag(const handle, suffix, prefix: string): IYAMLTagInfo;
    
    // Create verbatim URI tag
    class function CreateVerbatimTag(const uri: string): IYAMLTagInfo;
    
    // Create unresolved tag
    class function CreateUnresolvedTag(const originalText: string = '?'): IYAMLTagInfo;
    
    // Parse tag text and determine type automatically
    class function ParseTag(const tagText: string): IYAMLTagInfo;
    
    // Validation utilities
    class function IsValidTagHandle(const handle: string): Boolean;
    class function IsValidTagSuffix(const suffix: string): Boolean;
    class function IsValidTagURI(const uri: string): Boolean;
    
    // Utility methods
    class function CompareTagsByPriority(const tag1, tag2: IYAMLTagInfo): Integer;
    class function GetStandardTagType(const tagName: string): string;
  end;

implementation

uses
  System.StrUtils;

{ TYAMLTagInfo }

constructor TYAMLTagInfo.Create(ATagType: TYAMLTagType; const AOriginalText, AResolvedTag: string;
  const AHandle: string = ''; const ASuffix: string = ''; const APrefix: string = '');
begin
  inherited Create;
  FTagType := ATagType;
  FOriginalText := AOriginalText;
  FResolvedTag := AResolvedTag;
  FHandle := AHandle;
  FSuffix := ASuffix;
  FPrefix := APrefix;
end;

function TYAMLTagInfo.GetTagType: TYAMLTagType;
begin
  result := FTagType;
end;

function TYAMLTagInfo.GetOriginalText: string;
begin
  result := FOriginalText;
end;

function TYAMLTagInfo.GetResolvedTag: string;
begin
  result := FResolvedTag;
end;

function TYAMLTagInfo.GetHandle: string;
begin
  result := FHandle;
end;

function TYAMLTagInfo.GetSuffix: string;
begin
  result := FSuffix;
end;

function TYAMLTagInfo.GetPrefix: string;
begin
  result := FPrefix;
end;

function TYAMLTagInfo.IsStandardTag: boolean;
begin
  result := FTagType = TYAMLTagType.ytStandard;
end;

function TYAMLTagInfo.IsGlobalTag: boolean;
begin
  result := FTagType = TYAMLTagType.ytGlobal;
end;

function TYAMLTagInfo.IsLocalTag: boolean;
begin
  result := FTagType = TYAMLTagType.ytLocal;
end;

function TYAMLTagInfo.IsCustomTag: boolean;
begin
  result := FTagType = TYAMLTagType.ytCustom;
end;

function TYAMLTagInfo.IsVerbatimTag: boolean;
begin
  result := FTagType = TYAMLTagType.ytVerbatim;
end;

function TYAMLTagInfo.IsUnresolved: boolean;
begin
  result := FTagType = TYAMLTagType.ytUnresolved;
end;

function TYAMLTagInfo.AreEqual(const other: IYAMLTagInfo): boolean;
begin
  if other = nil then
    exit(False);

  result := (FTagType = other.TagType) and 
            SameText(FResolvedTag, other.ResolvedTag);
end;

function TYAMLTagInfo.ToString: string;
begin
  if FOriginalText <> '' then
    result := FOriginalText
  else
    result := FResolvedTag;
end;

{ TYAMLTagInfoFactory }

class function TYAMLTagInfoFactory.CreateFromText(const tagText: string; const resolvedURI: string = ''): IYAMLTagInfo;
var
  resolved: string;
begin
  if resolvedURI <> '' then
    resolved := resolvedURI
  else
    resolved := tagText;
    
  result := ParseTag(tagText);
end;

class function TYAMLTagInfoFactory.CreateStandardTag(const tagName: string): IYAMLTagInfo;
var
  originalText: string;
  resolvedURI: string;
begin
  originalText := '!!' + tagName;
  resolvedURI := 'tag:yaml.org,2002:' + tagName;
  
  result := TYAMLTagInfo.Create(TYAMLTagType.ytStandard, originalText, resolvedURI, '!!', tagName, 'tag:yaml.org,2002:');
end;

class function TYAMLTagInfoFactory.CreateLocalTag(const tagName: string): IYAMLTagInfo;
var
  originalText: string;
begin
  originalText := '!' + tagName;
  
  result := TYAMLTagInfo.Create(TYAMLTagType.ytLocal, originalText, originalText, '!', tagName, '!');
end;

class function TYAMLTagInfoFactory.CreateCustomTag(const handle, suffix, prefix: string): IYAMLTagInfo;
var
  originalText: string;
  resolvedURI: string;
begin
  originalText := handle + suffix;
  resolvedURI := prefix + suffix;
  
  result := TYAMLTagInfo.Create(TYAMLTagType.ytCustom, originalText, resolvedURI, handle, suffix, prefix);
end;

class function TYAMLTagInfoFactory.CreateVerbatimTag(const uri: string): IYAMLTagInfo;
var
  originalText: string;
begin
  originalText := '!<' + uri + '>';
  
  result := TYAMLTagInfo.Create(TYAMLTagType.ytVerbatim, originalText, uri, '', '', '');
end;

class function TYAMLTagInfoFactory.CreateUnresolvedTag(const originalText: string = '?'): IYAMLTagInfo;
begin
  result := TYAMLTagInfo.Create(TYAMLTagType.ytUnresolved, originalText, '', '', '', '');
end;

class function TYAMLTagInfoFactory.ParseTag(const tagText: string): IYAMLTagInfo;
var
  trimmedTag: string;
  secondExclamation : integer;
  handle : string;
  suffix : string;
begin
  trimmedTag := Trim(tagText);

  // Empty or unresolved tag
  if (trimmedTag = '') or (trimmedTag = '?') or (trimmedTag = '!') then
  begin
    result := CreateUnresolvedTag(trimmedTag);
    exit;
  end;

  // Verbatim tag format: !<uri>
  if (Length(trimmedTag) > 3) and StartsText('!<', trimmedTag) and EndsText('>', trimmedTag) then
  begin
    result := CreateVerbatimTag(Copy(trimmedTag, 3, Length(trimmedTag) - 3));
    exit;
  end;

  // Standard tag format: !!tagname
  if StartsText('!!', trimmedTag) then
  begin
    result := CreateStandardTag(Copy(trimmedTag, 3, Length(trimmedTag)));
    exit;
  end;

  // Local tag format: !tagname (not followed by another !)
  if StartsText('!', trimmedTag) and not StartsText('!!', trimmedTag) and (Pos('!', Copy(trimmedTag, 2, Length(trimmedTag))) = 0) then
  begin
    result := CreateLocalTag(Copy(trimmedTag, 2, Length(trimmedTag)));
    exit;
  end;

  // Custom tag format: !handle!suffix
  if StartsText('!', trimmedTag) then
  begin
    secondExclamation := Pos('!', Copy(trimmedTag, 2, Length(trimmedTag)));
    if secondExclamation > 0 then
    begin
      handle := Copy(trimmedTag, 1, secondExclamation + 1);
      suffix := Copy(trimmedTag, secondExclamation + 2, Length(trimmedTag));
      // For custom tags, we don't have the prefix here, it would come from TAG directives
      result := TYAMLTagInfo.Create(TYAMLTagType.ytCustom, trimmedTag, trimmedTag, handle, suffix, '');
      exit;
    end;
  end;
  
  // Check if it looks like a global URI
  if (Pos(':', trimmedTag) > 0) and not StartsText('!', trimmedTag) then
  begin
    result := TYAMLTagInfo.Create(TYAMLTagType.ytGlobal, trimmedTag, trimmedTag, '', '', '');
    exit;
  end;
  
  // Default to unresolved
  result := CreateUnresolvedTag(trimmedTag);
end;

class function TYAMLTagInfoFactory.IsValidTagHandle(const handle: string): Boolean;
var
  i: integer;
begin
  // Tag handles must start with ! and be followed by valid characters
  result := (Length(handle) >= 2) and 
            (handle[1] = '!') and 
            (handle[Length(handle)] = '!');
  
  // Empty handle ('!!') is valid for standard tags
  if result and (Length(handle) = 2) then
    exit(True);
    
  // Check that middle characters are valid (alphanumeric, -, _)
  for i := 2 to Length(handle) - 1 do
  begin
    if not (CharInSet(handle[i], ['a'..'z', 'A'..'Z', '0'..'9', '-', '_'])) then
    begin
      result := False;
      break;
    end;
  end;
end;

class function TYAMLTagInfoFactory.IsValidTagSuffix(const suffix: string): Boolean;
var
  i: integer;
begin
  result := True;
  
  // Suffix cannot be empty for custom tags
  if suffix = '' then
    exit(False);
    
  // Check for valid URI characters
  for i := 1 to Length(suffix) do
  begin
    if not (CharInSet(suffix[i], ['a'..'z', 'A'..'Z', '0'..'9', '-', '_', '.', '~', '/', ':', '@', '%'])) then
    begin
      result := False;
      break;
    end;
  end;
end;

class function TYAMLTagInfoFactory.IsValidTagURI(const uri: string): Boolean;
begin
  // Very basic URI validation - must contain scheme separator
  result := (uri <> '') and (Pos(':', uri) > 0);
end;

class function TYAMLTagInfoFactory.CompareTagsByPriority(const tag1, tag2: IYAMLTagInfo): Integer;
begin
  // Standard tags have highest priority
  if tag1.IsStandardTag and not tag2.IsStandardTag then
    result := -1
  else if not tag1.IsStandardTag and tag2.IsStandardTag then
    result := 1
  // Global tags have second priority  
  else if tag1.IsGlobalTag and not tag2.IsGlobalTag then
    result := -1
  else if not tag1.IsGlobalTag and tag2.IsGlobalTag then
    result := 1
  // Custom tags have third priority
  else if tag1.IsCustomTag and not tag2.IsCustomTag then
    result := -1
  else if not tag1.IsCustomTag and tag2.IsCustomTag then
    result := 1
  // Compare by resolved tag text
  else
    result := CompareText(tag1.ResolvedTag, tag2.ResolvedTag);
end;

class function TYAMLTagInfoFactory.GetStandardTagType(const tagName: string): string;
begin
  // Return the expected YAML type for standard tags
  if (tagName = 'str') or (tagName = 'string') then
    result := 'string'
  else if (tagName = 'int') or (tagName = 'integer') then
    result := 'integer'
  else if (tagName = 'float') or (tagName = 'real') then
    result := 'float'
  else if (tagName = 'bool') or (tagName = 'boolean') then
    result := 'boolean'
  else if tagName = 'null' then
    result := 'null'
  else if tagName = 'seq' then
    result := 'sequence'
  else if tagName = 'map' then
    result := 'mapping'
  else if tagName = 'set' then
    result := 'set'
  else if tagName = 'timestamp' then
    result := 'timestamp'
  else
    result := tagName;
end;

end.