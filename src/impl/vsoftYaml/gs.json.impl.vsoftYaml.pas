///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************

unit gs.json.impl.vsoftYaml;

interface

uses sysutils,
     classes,
     gs.Json,
     VSoft.YAML;

type

TgsJsonImplVSoftYaml = class(TInterfacedObject, igsJson)
private
protected
  FDoc : IYAMLDocument;
  FOwned : boolean;
public
  constructor Create; virtual;
  destructor Destroy; override;

  function parse(aJsonStr : string) : igsJson;
  function GetInternalJsonValue: TObject;
  function put(name : string; val : double) : igsJson; overload;
  function put(name : string; val : boolean) : igsJson; overload;
  function put(name : string; val : string) : igsJson; overload;

  //Array
  function put(name : string; vals : array of const) : igsJson; overload;
  function put(vals : array of const) : igsJson; overload;

  //Add an object.
  function put(name : string; val : igsJson) : igsJson; overload;
  function put(val : igsJson) : igsJson; overload;

  function stringify(var aStr : string) : igsJson; overload;
  function stringify : string; overload;

  function get(name : string; var value : string) : igsJson; overload;
  function get(index : integer; var value : string) : igsJson; overload;

  function get(name : string; var value : integer) : igsJson; overload;
  function get(index : integer; var value : integer) : igsJson; overload;

  function get(name : string; var value : Double) : igsJson; overload;
  function get(index : integer; var value : Double) : igsJson; overload;

  function get(name : string; var value : Boolean) : igsJson; overload;
  function get(index : integer; var value : Boolean) : igsJson; overload;

  //Object / Array
  function get(name : string; var value : igsJson) : igsJson; overload;
  function get(index : integer; var value : igsJson) : igsJson; overload;

  //Analyses.
  function jsonElementCount : integer;
  function jsonElementType(index : integer) : TgsJsonElementType;
  function jsonType : TgsJsonElementType;
  function jsonElementName(index : integer) : string;

  function clear : igsJson;

  //Base type easy access.
  function asString(name : String) : string;
  function asInteger(name : String) : integer;
  function asNumber(name : String) : double;
  function asBoolean(name : String) : Boolean;
  function asObj(name : String) : igsJson; overload;
  function asObj(index : integer) : igsJson; overload;

  function add(val : igsJson) : igsJson; overload;
  function add(val : double) : igsJson; overload;
  function add(val : integer) : igsJson; overload;
  function add(val : string) : igsJson; overload;
  function add(val : byte) : igsJson; overload;
  function add(val : boolean) : igsJson; overload;

  function isNameExists(name: String): boolean;

  function ToObj : igsJson;
  function ToArray : igsJson;
end;

TgsJsonImplVSoftYamlFactory = class(TInterfacedObject, igsJsonFactory)
  function getAuthor : string;
  function getTitle : string;
  function getDesc : string;
  function getId : string;
  function getJson : igsJson;
end;

implementation

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function valueToElementType(aValue : IYAMLValue) : TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if aValue = nil then
    exit;
  if aValue.IsNull then
    result := TgsJsonElementType.etNull
  else if aValue.IsBoolean then
    result := TgsJsonElementType.etBoolean
  else if aValue.IsInteger then
    result := TgsJsonElementType.etNumber
  else if aValue.IsFloat then
    result := TgsJsonElementType.etNumber
  else if aValue.IsString then
    result := TgsJsonElementType.etString
  else if aValue.IsMapping then
    result := TgsJsonElementType.etJson
  else if aValue.IsSequence then
    result := TgsJsonElementType.etJsonArray;
end;

procedure extractValue(source : IYAMLValue; var value : igsJson);
var
  w : TgsJsonImplVSoftYaml;
  subDoc : IYAMLDocument;
  js : string;
begin
  if not assigned(value) then
    value := TgsJsonImplVSoftYaml.Create;

  w := TgsJsonImplVSoftYaml(value);

  // Re-parse the sub-value into its own document so the wrapper holds a
  // fully independent IYAMLDocument that can be serialised / traversed.
  js := TYAML.WriteToJSONString(source);
  subDoc := TYAML.LoadFromString(js);
  w.FDoc := subDoc;
  w.FOwned := true;
end;

procedure ensureMapping(var FDoc : IYAMLDocument);
begin
  if (FDoc = nil) or (not FDoc.IsMapping) then
    FDoc := TYAML.CreateMapping;
end;

procedure ensureSequence(var FDoc : IYAMLDocument);
begin
  if (FDoc = nil) or (not FDoc.IsSequence) then
    FDoc := TYAML.CreateSequence;
end;

procedure addArrayOfConst(seq : IYAMLSequence; const vals : array of const);
var
  i : integer;
begin
  for i := Low(vals) to High(vals) do begin
    case vals[i].VType of
      vtString : seq.AddValue(string(vals[i].VString^));
      vtWideString : seq.AddValue(string(vals[i].VWideString));
      vtUnicodeString : seq.AddValue(string(vals[i].VUnicodeString));
      vtInteger : seq.AddValue(Int32(vals[i].VInteger));
      System.vtBoolean : seq.AddValue(vals[i].VBoolean);
      vtExtended : seq.AddValue(Double(vals[i].VExtended^));
    end;
  end;
end;

// Helper: return IYAMLValue for an element at a given index (mapping or sequence)
function getValueAtIndex(doc : IYAMLDocument; index : integer) : IYAMLValue;
begin
  result := nil;
  if doc = nil then exit;
  if doc.IsMapping then begin
    var key := doc.AsMapping.Keys[index];
    result := doc.AsMapping.Items[key];
  end
  else if doc.IsSequence then
    result := doc.AsSequence.Items[index];
end;

// ---------------------------------------------------------------------------
// TgsJsonImplVSoftYaml
// ---------------------------------------------------------------------------

constructor TgsJsonImplVSoftYaml.Create;
begin
  FDoc := nil;
  FOwned := true;
end;

function TgsJsonImplVSoftYaml.GetInternalJsonValue: TObject;
begin
  Result := nil;
end;

destructor TgsJsonImplVSoftYaml.Destroy;
begin
  FDoc := nil;
  inherited;
end;

function TgsJsonImplVSoftYaml.parse(aJsonStr: string): igsJson;
var
  trimmed : string;
begin
  result := self;
  trimmed := aJsonStr.Trim;
  if trimmed = '' then
    raise JsonException.Create('Empty JSON string');
  FDoc := TYAML.LoadFromString(trimmed);
  if FDoc = nil then
    raise JsonException.Create('JSON parse error: ' + aJsonStr);
  FOwned := true;
end;

// -- put (object key/value) ------------------------------------------------

function TgsJsonImplVSoftYaml.put(name: string; val: double): igsJson;
begin
  result := self;
  ensureMapping(FDoc);
  FDoc.AsMapping.AddOrSetValue(name, val);
end;

function TgsJsonImplVSoftYaml.put(name, val: string): igsJson;
begin
  result := self;
  ensureMapping(FDoc);
  FDoc.AsMapping.AddOrSetValue(name, val);
end;

function TgsJsonImplVSoftYaml.put(name: string; val: boolean): igsJson;
begin
  result := self;
  ensureMapping(FDoc);
  FDoc.AsMapping.AddOrSetValue(name, val);
end;

function TgsJsonImplVSoftYaml.put(vals: array of const): igsJson;
begin
  result := self;
  ensureSequence(FDoc);
  addArrayOfConst(FDoc.AsSequence, vals);
end;

function TgsJsonImplVSoftYaml.put(name: string; vals: array of const): igsJson;
var
  seq : IYAMLSequence;
begin
  result := self;
  ensureMapping(FDoc);
  seq := FDoc.AsMapping.AddOrSetSequence(name);
  addArrayOfConst(seq, vals);
end;

function TgsJsonImplVSoftYaml.put(name: string; val: igsJson): igsJson;
var
  subDoc : IYAMLDocument;
  js : string;
begin
  result := self;
  ensureMapping(FDoc);
  js := val.stringify;
  subDoc := TYAML.LoadFromString(js);
  if subDoc <> nil then begin
    if subDoc.IsMapping then
      FDoc.AsMapping.AddOrSetMapping(name).AsCollection.Clear
    else if subDoc.IsSequence then
      FDoc.AsMapping.AddOrSetSequence(name).AsCollection.Clear;
    // Re-serialize & re-inject via string round-trip to keep things clean
    // Actually: just set via AddOrSetValue using the string value then re-parse
    // Simplest correct approach: build from scratch via string concat
  end;
  // Most reliable approach: serialize parent, inject, re-parse
  // But simpler: serialize the child, embed via the mapping's typed setters
  // For objects we use O[key], for arrays A[key], for scalars direct set
  if subDoc <> nil then begin
    if subDoc.IsMapping then begin
      var childMap := FDoc.AsMapping.AddOrSetMapping(name);
      // copy all keys from subDoc mapping into childMap
      var srcMap := subDoc.AsMapping;
      for var i := 0 to srcMap.Count - 1 do begin
        var k := srcMap.Keys[i];
        var v := srcMap.Items[k];
        // Use string round-trip for child values
        var childJs := TYAML.WriteToJSONString(v);
        var childSubDoc := TYAML.LoadFromString(childJs);
        if childSubDoc.IsMapping then
          childMap.O[k] := childSubDoc.AsMapping
        else if childSubDoc.IsSequence then
          childMap.A[k] := childSubDoc.AsSequence
        else begin
          // scalar
          if v.IsNull then
            childMap.AddOrSetValue(k, 'null')
          else if v.IsBoolean then
            childMap.AddOrSetValue(k, v.AsBoolean)
          else if v.IsInteger then
            childMap.AddOrSetValue(k, v.AsInteger)
          else if v.IsFloat then
            childMap.AddOrSetValue(k, v.AsFloat)
          else
            childMap.AddOrSetValue(k, v.AsString);
        end;
      end;
    end
    else if subDoc.IsSequence then begin
      var childSeq := FDoc.AsMapping.AddOrSetSequence(name);
      var srcSeq := subDoc.AsSequence;
      for var i := 0 to srcSeq.Count - 1 do begin
        var v := srcSeq.Items[i];
        if v.IsMapping then
          childSeq.AddMapping
        else if v.IsSequence then
          childSeq.AddSequence
        else if v.IsBoolean then
          childSeq.AddValue(v.AsBoolean)
        else if v.IsInteger then
          childSeq.AddValue(v.AsInteger)
        else if v.IsFloat then
          childSeq.AddValue(v.AsFloat)
        else
          childSeq.AddValue(v.AsString);
      end;
    end
    else begin
      // scalar root - just set string value
      FDoc.AsMapping.AddOrSetValue(name, js);
    end;
  end;
end;

function TgsJsonImplVSoftYaml.put(val: igsJson): igsJson;
var
  subDoc : IYAMLDocument;
  js : string;
begin
  result := self;
  ensureSequence(FDoc);
  js := val.stringify;
  subDoc := TYAML.LoadFromString(js);
  if (subDoc <> nil) then begin
    // For adding sub-objects/arrays into a sequence, the cleanest approach
    // is to serialize parent, re-parse. But for direct API usage:
    if subDoc.IsMapping then begin
      var childMap := FDoc.AsSequence.AddMapping;
      var srcMap := subDoc.AsMapping;
      for var i := 0 to srcMap.Count - 1 do begin
        var k := srcMap.Keys[i];
        var v := srcMap.Items[k];
        if v.IsNull then
          childMap.AddOrSetValue(k, 'null')
        else if v.IsBoolean then
          childMap.AddOrSetValue(k, v.AsBoolean)
        else if v.IsInteger then
          childMap.AddOrSetValue(k, v.AsInteger)
        else if v.IsFloat then
          childMap.AddOrSetValue(k, v.AsFloat)
        else if v.IsMapping then begin
          var nestedJs := TYAML.WriteToJSONString(v);
          var nestedDoc := TYAML.LoadFromString(nestedJs);
          if nestedDoc.IsMapping then
            childMap.O[k] := nestedDoc.AsMapping;
        end
        else if v.IsSequence then begin
          var nestedJs := TYAML.WriteToJSONString(v);
          var nestedDoc := TYAML.LoadFromString(nestedJs);
          if nestedDoc.IsSequence then
            childMap.A[k] := nestedDoc.AsSequence;
        end
        else
          childMap.AddOrSetValue(k, v.AsString);
      end;
    end
    else if subDoc.IsSequence then begin
      var childSeq := FDoc.AsSequence.AddSequence;
      var srcSeq := subDoc.AsSequence;
      for var i := 0 to srcSeq.Count - 1 do begin
        var v := srcSeq.Items[i];
        if v.IsBoolean then
          childSeq.AddValue(v.AsBoolean)
        else if v.IsInteger then
          childSeq.AddValue(v.AsInteger)
        else if v.IsFloat then
          childSeq.AddValue(v.AsFloat)
        else
          childSeq.AddValue(v.AsString);
      end;
    end
    else begin
      // scalar - add as string
      FDoc.AsSequence.AddValue(js);
    end;
  end;
end;

// -- stringify --------------------------------------------------------------

function TgsJsonImplVSoftYaml.stringify(var aStr: string): igsJson;
begin
  result := self;
  if FDoc <> nil then begin
    FDoc.Options.PrettyPrint := false;
    aStr := TYAML.WriteToJSONString(FDoc);
  end
  else
    aStr := 'null';
end;

function TgsJsonImplVSoftYaml.stringify: string;
begin
  if FDoc <> nil then begin
    FDoc.Options.PrettyPrint := false;
    result := TYAML.WriteToJSONString(FDoc);
  end
  else
    result := 'null';
end;

// -- get (by name) ----------------------------------------------------------

function TgsJsonImplVSoftYaml.get(name: string; var value: string): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.IsMapping then begin
    if FDoc.AsMapping.ContainsKey(name) then begin
      v := FDoc.AsMapping.Items[name];
      value := v.AsString;
    end
    else
      raise JsonException.Create('TgsJsonImplVSoftYaml.get: Key not found: ' + name);
  end
  else
    raise JsonException.Create('TgsJsonImplVSoftYaml.get: Not an object');
end;

function TgsJsonImplVSoftYaml.get(name: string; var value: integer): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.IsMapping then begin
    v := FDoc.AsMapping.Items[name];
    value := Integer(v.AsInteger);
  end
  else
    raise JsonException.Create('TgsJsonImplVSoftYaml.get: Not an object');
end;

function TgsJsonImplVSoftYaml.get(name: string; var value: Double): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.IsMapping then begin
    v := FDoc.AsMapping.Items[name];
    if v.IsInteger then
      value := v.AsInteger
    else
      value := v.AsFloat;
  end
  else
    raise JsonException.Create('TgsJsonImplVSoftYaml.get: Not an object');
end;

function TgsJsonImplVSoftYaml.get(name: string; var value: Boolean): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.IsMapping then begin
    v := FDoc.AsMapping.Items[name];
    value := v.AsBoolean;
  end
  else
    raise JsonException.Create('TgsJsonImplVSoftYaml.get: Not an object');
end;

function TgsJsonImplVSoftYaml.get(name: string; var value: igsJson): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.IsMapping then begin
    if FDoc.AsMapping.ContainsKey(name) then begin
      v := FDoc.AsMapping.Items[name];
      extractValue(v, value);
    end
    else
      raise JsonException.Create('TgsJsonImplVSoftYaml.get: Key not found: ' + name);
  end
  else
    raise JsonException.Create('TgsJsonImplVSoftYaml.get: Not an object');
end;

// -- get (by index) ---------------------------------------------------------

function TgsJsonImplVSoftYaml.get(index: integer; var value: string): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  if (FDoc <> nil) and FDoc.IsMapping then begin
    var key := FDoc.AsMapping.Keys[index];
    v := FDoc.AsMapping.Items[key];
    value := v.AsString;
  end
  else if (FDoc <> nil) and FDoc.IsSequence then begin
    v := FDoc.AsSequence.Items[index];
    value := v.AsString;
  end;
end;

function TgsJsonImplVSoftYaml.get(index: integer; var value: integer): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  v := getValueAtIndex(FDoc, index);
  if v <> nil then
    value := Integer(v.AsInteger);
end;

function TgsJsonImplVSoftYaml.get(index: integer; var value: Double): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  v := getValueAtIndex(FDoc, index);
  if v <> nil then begin
    if v.IsInteger then
      value := v.AsInteger
    else
      value := v.AsFloat;
  end;
end;

function TgsJsonImplVSoftYaml.get(index: integer; var value: Boolean): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  v := getValueAtIndex(FDoc, index);
  if v <> nil then
    value := v.AsBoolean;
end;

function TgsJsonImplVSoftYaml.get(index: integer; var value: igsJson): igsJson;
var
  v : IYAMLValue;
begin
  result := self;
  v := getValueAtIndex(FDoc, index);
  if v <> nil then
    extractValue(v, value);
end;

// -- jsonElement* / jsonType ------------------------------------------------

function TgsJsonImplVSoftYaml.jsonElementCount: integer;
begin
  if (FDoc <> nil) and FDoc.IsMapping then
    result := FDoc.AsMapping.Count
  else if (FDoc <> nil) and FDoc.IsSequence then
    result := FDoc.AsSequence.Count
  else
    result := -1;
end;

function TgsJsonImplVSoftYaml.jsonElementType(index: integer): TgsJsonElementType;
var
  v : IYAMLValue;
begin
  result := TgsJsonElementType.etEmpty;
  v := getValueAtIndex(FDoc, index);
  if v <> nil then
    result := valueToElementType(v);
end;

function TgsJsonImplVSoftYaml.jsonType: TgsJsonElementType;
begin
  result := TgsJsonElementType.etEmpty;
  if FDoc = nil then
    exit;
  if FDoc.IsNull then
    result := TgsJsonElementType.etNull
  else if FDoc.IsMapping then
    result := TgsJsonElementType.etJson
  else if FDoc.IsSequence then
    result := TgsJsonElementType.etJsonArray
  else if FDoc.IsScalar then begin
    var root := FDoc.Root;
    if root.IsBoolean then
      result := TgsJsonElementType.etBoolean
    else if root.IsInteger then
      result := TgsJsonElementType.etNumber
    else if root.IsFloat then
      result := TgsJsonElementType.etNumber
    else if root.IsString then
      result := TgsJsonElementType.etString
    else if root.IsNull then
      result := TgsJsonElementType.etNull;
  end;
end;

function TgsJsonImplVSoftYaml.jsonElementName(index: integer): string;
begin
  result := '';
  if (FDoc <> nil) and FDoc.IsMapping then begin
    assert(index < FDoc.AsMapping.Count);
    result := FDoc.AsMapping.Keys[index];
  end
  else
    raise JsonException.Create('TgsJsonImplVSoftYaml.jsonElementName: Not an object');
end;

// -- clear ------------------------------------------------------------------

function TgsJsonImplVSoftYaml.clear: igsJson;
begin
  result := self;
  FDoc := nil;
  FOwned := true;
end;

// -- asXxx (easy access) ----------------------------------------------------

function TgsJsonImplVSoftYaml.asString(name: String): string;
begin
  get(name, result);
end;

function TgsJsonImplVSoftYaml.asInteger(name: String): integer;
begin
  get(name, result);
end;

function TgsJsonImplVSoftYaml.asNumber(name: String): double;
begin
  get(name, result);
end;

function TgsJsonImplVSoftYaml.asBoolean(name: String): Boolean;
begin
  get(name, result);
end;

function TgsJsonImplVSoftYaml.asObj(name: String): igsJson;
begin
  get(name, result);
end;

function TgsJsonImplVSoftYaml.asObj(index: integer): igsJson;
begin
  get(index, result);
end;

// -- add (to array) ---------------------------------------------------------

function TgsJsonImplVSoftYaml.add(val: igsJson): igsJson;
var
  subDoc : IYAMLDocument;
  js : string;
begin
  result := self;
  ensureSequence(FDoc);
  js := val.stringify;
  subDoc := TYAML.LoadFromString(js);
  if (subDoc <> nil) then begin
    if subDoc.IsMapping then begin
      var childMap := FDoc.AsSequence.AddMapping;
      var srcMap := subDoc.AsMapping;
      for var i := 0 to srcMap.Count - 1 do begin
        var k := srcMap.Keys[i];
        var v := srcMap.Items[k];
        if v.IsBoolean then
          childMap.AddOrSetValue(k, v.AsBoolean)
        else if v.IsInteger then
          childMap.AddOrSetValue(k, v.AsInteger)
        else if v.IsFloat then
          childMap.AddOrSetValue(k, v.AsFloat)
        else
          childMap.AddOrSetValue(k, v.AsString);
      end;
    end
    else if subDoc.IsSequence then begin
      var childSeq := FDoc.AsSequence.AddSequence;
      var srcSeq := subDoc.AsSequence;
      for var i := 0 to srcSeq.Count - 1 do begin
        var v := srcSeq.Items[i];
        if v.IsBoolean then
          childSeq.AddValue(v.AsBoolean)
        else if v.IsInteger then
          childSeq.AddValue(v.AsInteger)
        else if v.IsFloat then
          childSeq.AddValue(v.AsFloat)
        else
          childSeq.AddValue(v.AsString);
      end;
    end
    else begin
      FDoc.AsSequence.AddValue(js);
    end;
  end;
end;

function TgsJsonImplVSoftYaml.add(val: double): igsJson;
begin
  result := self;
  ensureSequence(FDoc);
  FDoc.AsSequence.AddValue(val);
end;

function TgsJsonImplVSoftYaml.add(val: integer): igsJson;
begin
  result := self;
  ensureSequence(FDoc);
  FDoc.AsSequence.AddValue(Int32(val));
end;

function TgsJsonImplVSoftYaml.add(val: string): igsJson;
begin
  result := self;
  ensureSequence(FDoc);
  FDoc.AsSequence.AddValue(val);
end;

function TgsJsonImplVSoftYaml.add(val: byte): igsJson;
begin
  result := self;
  ensureSequence(FDoc);
  FDoc.AsSequence.AddValue(Int32(val));
end;

function TgsJsonImplVSoftYaml.add(val: boolean): igsJson;
begin
  result := self;
  ensureSequence(FDoc);
  FDoc.AsSequence.AddValue(val);
end;

// -- isNameExists -----------------------------------------------------------

function TgsJsonImplVSoftYaml.isNameExists(name: String): boolean;
begin
  result := false;
  if (FDoc <> nil) and FDoc.IsMapping then
    result := FDoc.AsMapping.ContainsKey(name);
end;

// -- ToObj / ToArray ---------------------------------------------------------

function TgsJsonImplVSoftYaml.ToObj: igsJson;
begin
  result := self;
  if (FDoc = nil) or (not FDoc.IsMapping) then begin
    FDoc := TYAML.CreateMapping;
    FOwned := true;
  end;
end;

function TgsJsonImplVSoftYaml.ToArray: igsJson;
begin
  result := self;
  if (FDoc = nil) or (not FDoc.IsSequence) then begin
    FDoc := TYAML.CreateSequence;
    FOwned := true;
  end;
end;

// ---------------------------------------------------------------------------
// TgsJsonImplVSoftYamlFactory
// ---------------------------------------------------------------------------

function TgsJsonImplVSoftYamlFactory.getAuthor: string;
begin
  result := 'VSoft Technologies';
end;

function TgsJsonImplVSoftYamlFactory.getTitle: string;
begin
  result := 'VSoft.YAML (JSON mode)';
end;

function TgsJsonImplVSoftYamlFactory.getDesc: string;
begin
  result := '';
end;

function TgsJsonImplVSoftYamlFactory.getId: string;
begin
  result := 'vsoftyaml';
end;

function TgsJsonImplVSoftYamlFactory.getJson: igsJson;
begin
  result := TgsJsonImplVSoftYaml.Create;
end;

initialization

TYAML.DefaultParserOptions.JSONMode := true;
TYAML.DefaultWriterOptions.PrettyPrint := false;
TYAML.DefaultWriterOptions.Encoding := TEncoding.UTF8;

addImplementation(TgsJsonImplVSoftYamlFactory.Create);

end.
