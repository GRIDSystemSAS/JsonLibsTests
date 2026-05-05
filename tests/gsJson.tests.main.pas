///*******************************************************
///
/// JsonLibsTests
///
/// 2026-2027 Grid System SAS
///
///
///*******************************************************
unit gsJson.tests.main;

interface

uses
  SysUtils,
  classes,
  DUnitX.TestFramework,
  gs.Json,
  gs.Json.impl.chimera,
  gs.Json.impl.gsJson,
  gs.json.impl.delphiJson,
  gs.json.impl.beroJson,
  gs.json.impl.lkJson,
  gs.json.impl.jsonDoc,
  gs.json.impl.jdo,
  gs.Json.Impl.mcJson,
  gs.json.impl.json4Delphi,
  gs.json.impl.xSuperObject,
  gs.json.impl.superObject,
  gs.json.impl.myJson,
  gs.json.impl.dwsJson,
  gs.json.impl.dynamicDataObjects,
  gs.json.impl.neslibJson,
  gs.json.impl.grijjyBson,
  gs.json.impl.mormot,
  gs.json.impl.vsoftYaml;

type
  [TestFixture]
  TgsJson_gsJson_TestProject = class
  private
  public
    lstr : String;
    ljson : igsJson;
    [Setup]
    procedure Setup; virtual;
    [TearDown]
    procedure TearDown;
    // Sample Methods
    // Simple single Test
    [Test]
    [TestCase('Test A','{"aa":"10.005"}','')]
    [TestCase('Test B','{"aa":"10.004","bob":1}','')]
    [TestCase('Test C','{"aa":"10.044","bob":31,"co":[1,2,3]}','')]
    [TestCase('Test D','[{"aa":"10.044","bob":31,"co":[1,2,3]}]','')]
    [TestCase('Test E','[{"aa":"10.004","bob":1},{"aa":"10.04","bob":2},{"aa":"Hi","bob":3}]','')]
    [TestCase('Test F','12','')]
    [TestCase('Test G','null','')]
    [TestCase('Test H','""','')]
    [TestCase('Test I','" "','')]
    [TestCase('Test J','"Hello"','')]
    [TestCase('Test K','true','')]
    [TestCase('Test L','false','')]
    [TestCase('Test Empty A','{}','')]
    [TestCase('Test Empty B','[]','')]
    [TestCase('Test Empty C','{  }','')]
    [TestCase('Test Empty D','[  ]','')]
    [TestCase('Test Empty E','  [  ]','')]
    procedure Test_Parse(const a : string);
    [Test]
    [TestCase('Test Empty A (not allowed)','','')]
    [TestCase('Test Empty B With space (not allowed)','   ','')]
    [TestCase('Test Parse error A (line break not allowed)',' " '+sLineBreak+' "','')]
    [TestCase('Test Parse error B (pure string)','Hello','')]
    [TestCase('Test Parse error C (Json object has always pairs declared (here "31" is not named - Not allowed','{"aa":"10.044",31,"co":[1,2,3]}','')]

    procedure Test_ParseErrorbutOk(const a : string);

    [Test]
    procedure Test_DuplicateKey_RFC8259;

    [Test]
    [TestCase('Test Get 1','{"aa":"10.004","bob":18}','')]
    procedure Test_get_1(const a : string);
    [Test]
    [TestCase('Test Get 2','{"ip": "8.8.8.8"}','')]
    procedure Test_get_2(const a : string);
    [Test]
    procedure test_get_integer;
    [Test]
    procedure Test_getAndJsonElement;
    [Test]
    procedure test_arrayAndVariousGet;
    [Test]
    [TestCase('Test Put A','Hello World','')]
    [TestCase('Test Put B','ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½ï¿½&','')]
    procedure Test_PutAndGetStr(const a : string);

    [Test]
    [TestCase('Test array build A','1,2,5')]
    procedure Test_SimpleIntegerArray(const AValue1 : Integer;const AValue2 : Integer);
    [TestCase('Test array build B','1,2,5,Hi...')]
    procedure Test_PolymorphicArray(const AValue : String);
    [TestCase('Test array build C (empty array)','')]
    procedure Test_BuildEmptyArray(const AValue : String);

    // RFC 8259 Section 6 - Valid Number Formats (strict)
    // Note: DUnitX TestCase 3rd arg = separator, using '|'
    [Test]
    [TestCase('Zero',            '{"v":0}|0',              '|')]
    [TestCase('Negative zero',   '{"v":-0}|0',             '|')]
    [TestCase('Positive int',    '{"v":42}|42',            '|')]
    [TestCase('Negative int',    '{"v":-42}|-42',          '|')]
    [TestCase('Decimal',         '{"v":3.14}|3.14',        '|')]
    [TestCase('Negative decimal','{"v":-0.5}|-0.5',        '|')]
    [TestCase('Exponent lower',  '{"v":1e10}|10000000000', '|')]
    [TestCase('Exponent upper',  '{"v":1E10}|10000000000', '|')]
    [TestCase('Exponent plus',   '{"v":1e+2}|100',         '|')]
    [TestCase('Exponent minus',  '{"v":1e-2}|0.01',        '|')]
    [TestCase('Decimal exp',     '{"v":1.5e2}|150',        '|')]
    [TestCase('Negative exp',    '{"v":-1.5e-2}|-0.015',   '|')]
    procedure Test_RFC8259_NumberFormats(const aJson: string; const aExpected: string);

    // RFC 8259 Section 6 - Invalid Number Formats (permissive)
    [Test]
    [TestCase('Leading plus',  '{"v":+1}',        '')]
    [TestCase('Leading zero',  '{"v":01}',        '')]
    [TestCase('Dot start',     '{"v":.5}',        '')]
    [TestCase('Dot end',       '{"v":1.}',        '')]
    [TestCase('NaN',           '{"v":NaN}',       '')]
    [TestCase('Infinity',      '{"v":Infinity}',  '')]
    [TestCase('Neg Infinity',  '{"v":-Infinity}', '')]
    [TestCase('Hex',           '{"v":0xFF}',      '')]
    procedure Test_RFC8259_NumberInvalid(const aJson: string); virtual;

    // RFC 8259 Section 7 - String Escape Sequences (strict)
    [Test]
    procedure Test_RFC8259_StringEscapes;

    // RFC 8259 Section 7 - Unicode Escapes BMP (strict)
    [Test]
    procedure Test_RFC8259_UnicodeEscapes;

    // RFC 8259 Section 7 - Surrogate Pairs (permissive)
    [Test]
    procedure Test_RFC8259_SurrogatePairs;

    // RFC 8259 Section 7 - String Round-trip with control chars (strict)
    [Test]
    procedure Test_RFC8259_StringRoundTrip;

    // RFC 8259 Section 2 - Whitespace between tokens (strict)
    [Test]
    procedure Test_RFC8259_Whitespace;

    // RFC 8259 Section 4/5 - Deep Nesting (strict)
    [Test]
    procedure Test_RFC8259_DeepNesting;

    // RFC 8259 Section 9 - Trailing Comma (permissive)
    [Test]
    procedure Test_RFC8259_TrailingComma;

    // RFC 8259 Section 8 - UTF-8 Multibyte characters (strict)
    [Test]
    procedure Test_RFC8259_UTF8Multibyte;

    [Test]
    procedure Test_Stringify;
  end;

  [TestFixture]
  TgsJson_mcJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_embarcaderoDelphiJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_beroJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_lkJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_jsonDoc_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_jdo_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_xSuperObject_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_json4Delphi_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_superObject_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_myJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_chimera_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_dwsJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_dynamicDataObjects_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_neslibJson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_grijjyBson_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_mormot2_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
  end;

  [TestFixture]
  TgsJson_vsoftYaml_TestProject = class(TgsJson_gsJson_TestProject)
  public
    [Setup]
    procedure Setup; override;
    procedure Test_RFC8259_NumberInvalid(const aJson: string); override;
  end;

implementation

procedure TgsJson_gsJson_TestProject.Setup;
begin
 ljson := CreateJson('gsjson');
end;

procedure TgsJson_gsJson_TestProject.TearDown;
begin
end;

procedure TgsJson_gsJson_TestProject.Test_BuildEmptyArray(const AValue: String);
begin
  ljson.put([]);
  var l := ljson.stringify;
  Assert.IsTrue(l='[]');
end;

procedure TgsJson_gsJson_TestProject.Test_getAndJsonElement;
begin
  var ln := ljson.parse('{"ip": "8.8.8.8"}').jsonElementName(0);
  assert.IsTrue(ln='ip');
  ljson.parse('{"ip": "8.8.8.8"}').get(ln,lstr);
  assert.IsTrue(lstr='8.8.8.8');
end;

procedure TgsJson_gsJson_TestProject.Test_get_1(const a: string);
begin
  var lstr : string;
  var lbob : integer;
  ljson.parse(a).get('aa',lstr).get('bob',lbob);
  assert.Istrue(lstr='10.004');
  assert.Istrue(lbob=18);
end;

procedure TgsJson_gsJson_TestProject.Test_get_2(const a: string);
begin
  var lstr : string;
  ljson.parse(a).get('ip',lstr);
  assert.Istrue(lstr='8.8.8.8');
end;

procedure TgsJson_gsJson_TestProject.test_get_integer;
begin
 var lbob : integer;
 ljson.parse('{"aa":"10.004","bob":1,"co":[1,2,3]}').get('bob',lbob);
 assert.istrue(lbob=1);
end;

procedure TgsJson_gsJson_TestProject.Test_Parse(const a : string);
begin
 TDUnitX.CurrentRunner.Status('Test_Parse - '+a);
 ljson.parse(a);
 Assert.Pass;
end;

procedure TgsJson_gsJson_TestProject.Test_ParseErrorButOk(const a: string);
begin
  try
    ljson.parse(a);
  Except
    Assert.Pass;
  end;
  Assert.Fail;
end;

procedure TgsJson_gsJson_TestProject.Test_DuplicateKey_RFC8259;
const
  CJSON_DUPLICATE = '{"aa":"10.044","co":[1,2,3],"aa":"override"}';
begin
  try
    ljson.parse(CJSON_DUPLICATE);
  except
    Log('Duplicate key: parser rejects duplicate keys (strict mode).');
    Assert.Pass;
    Exit;
  end;
  Log('WARNING - RFC 8259 Section 4: "The names within an object SHOULD be unique." '
    + 'This parser silently accepts duplicate keys. Interoperability is NOT guaranteed.');
  Assert.Pass;
end;

procedure TgsJson_gsJson_TestProject.Test_PutAndGetStr(const a: string);
var lv,lv2 :String;
begin
  Log('get by index');
  ljson.put('val',a).get(0,lv);
  Assert.IsTrue(lv=a);
  Log('get by name');
  ljson.put('val',a).get('val',lv2);
  Assert.IsTrue(lv2=a);
end;

procedure TgsJson_gsJson_TestProject.Test_SimpleIntegerArray(const AValue1 : Integer;const AValue2 : Integer);
var lj : IgsJson;
    lv : integer;
begin
  ljson.put('test',[AValue1,AValue2]).get('test',lj);
  lj.get(1,lv);
  assert.IsTrue(lv = 2);
end;

procedure TgsJson_gsJson_TestProject.Test_PolymorphicArray(
  const AValue: String);
var lj : IgsJson;
    lv0,lv1,lv2 : integer;
    lv3 : String;
    lv4 : double;
    lv5,lv6 : boolean;
    lv7 : integer;
begin
  //How to transfor aValue into a TVarRec array... lol.
  ljson.put('test',[1,2,5,'Hi',3.14,true,false,-1]).get('test',lj);
  lj.get(0,lv0);
  lj.get(1,lv1);
  lj.get(2,lv2);
  lj.get(3,lv3);
  lj.get(4,lv4);
  lj.get(5,lv5);
  lj.get(6,lv6);
  lj.get(7,lv7);

  assert.IsTrue(lv0 = 1);
  assert.IsTrue(lv1 = 2);
  assert.IsTrue(lv2 = 5);
  assert.IsTrue(lv3 = 'Hi');
  assert.IsTrue(lv5 = true);
  assert.IsTrue(lv6 = false);
  assert.IsTrue(lv7 = -1);

//  assert.IsTrue(lv4 = 3.14); //??
end;

procedure TgsJson_gsJson_TestProject.test_arrayAndVariousGet;
begin
 var lbob : integer;
 var la : igsJson;
 ljson.parse('{"aa":"10.044","bob":31,"co":[1,2,3]}').get('co',la).get('bob',lbob);
 assert.IsTrue(la.jsonElementCount=3);
 assert.IsTrue(lbob=31);
 la.get(1,lbob);
 assert.IsTrue(lbob=2);
end;

{ RFC 8259 Section 6 - Number Formats }

procedure TgsJson_gsJson_TestProject.Test_RFC8259_NumberFormats(
  const aJson, aExpected: string);
var
  d: Double;
  expected: Double;
  fs: TFormatSettings;
begin
  ljson.parse(aJson);
  Assert.IsTrue(ljson.jsonElementType(0) = TgsJsonElementType.etNumber,
    'Expected number type for ' + aJson);
  ljson.get('v', d);
  fs := TFormatSettings.Create;
  fs.DecimalSeparator := '.';
  fs.ThousandSeparator := #0;
  expected := StrToFloat(aExpected, fs);
  Assert.AreEqual(expected, d, Abs(expected) * 1e-9 + 1e-15,
    'Value mismatch for ' + aJson);
end;

procedure TgsJson_gsJson_TestProject.Test_RFC8259_NumberInvalid(
  const aJson: string);
begin
  try
    ljson.parse(aJson);
  except
    Log('RFC 8259 Section 6: Correctly rejects invalid number format: ' + aJson);
    Assert.Pass;
    Exit;
  end;
  Log('WARNING - RFC 8259 Section 6: Parser accepts non-conforming number: '
    + aJson + '. Interoperability NOT guaranteed.');
  Assert.Pass;
end;

{ RFC 8259 Section 7 - String Escapes }

procedure TgsJson_gsJson_TestProject.Test_RFC8259_StringEscapes;
const
  CJSON = '{"a":"line1\nline2","b":"col1\tcol2","c":"back\\slash",'
        + '"d":"quote\"here","e":"slash\/ok","f":"\b\f\r"}';
var
  s: string;
begin
  ljson.parse(CJSON);
  ljson.get('a', s);
  Assert.AreEqual('line1'#10'line2', s, '\n escape failed');
  ljson.get('b', s);
  Assert.AreEqual('col1'#9'col2', s, '\t escape failed');
  ljson.get('c', s);
  Assert.AreEqual('back\slash', s, '\\ escape failed');
  ljson.get('d', s);
  Assert.AreEqual('quote"here', s, '\" escape failed');
  ljson.get('e', s);
  Assert.AreEqual('slash/ok', s, '\/ escape failed');
  ljson.get('f', s);
  Assert.IsTrue(Pos(#8, s) > 0, '\b not found in result');
  Assert.IsTrue(Pos(#12, s) > 0, '\f not found in result');
  Assert.IsTrue(Pos(#13, s) > 0, '\r not found in result');
end;

procedure TgsJson_gsJson_TestProject.Test_RFC8259_UnicodeEscapes;
const
  CJSON = '{"a":"\u0041","b":"\u00E9","c":"\u4E16"}';
var
  s: string;
begin
  ljson.parse(CJSON);
  ljson.get('a', s);
  Assert.AreEqual('A', s, '\u0041 should decode to A');
  ljson.get('b', s);
  Assert.IsTrue((Length(s) = 1) and (Ord(s[1]) = $00E9),
    '\u00E9 should decode to e-acute (U+00E9)');
  ljson.get('c', s);
  Assert.IsTrue((Length(s) = 1) and (Ord(s[1]) = $4E16),
    '\u4E16 should decode to CJK character (U+4E16)');
end;

procedure TgsJson_gsJson_TestProject.Test_RFC8259_SurrogatePairs;
const
  CJSON = '{"emoji":"\uD83D\uDE00"}';
var
  s: string;
begin
  try
    ljson.parse(CJSON);
    ljson.get('emoji', s);
    Assert.IsTrue(Length(s) > 0, 'Surrogate pair decoded to empty string');
    Log('Surrogate pair support: OK (' + IntToStr(Length(s)) + ' char(s))');
  except
    on E: Exception do
      Log('RFC 8259 Section 7: Surrogate pairs not supported: ' + E.Message);
  end;
  Assert.Pass;
end;

procedure TgsJson_gsJson_TestProject.Test_RFC8259_StringRoundTrip;
var
  s, json: string;
begin
  ljson.put('text', 'line1'#10'line2'#9'tab');
  json := ljson.stringify;
  // Round-trip: clear, re-parse, verify value preserved
  ljson.clear;
  ljson.parse(json);
  ljson.get('text', s);
  Assert.AreEqual('line1'#10'line2'#9'tab', s,
    'String round-trip failed for control characters');
end;

{ RFC 8259 Section 2 - Whitespace }

procedure TgsJson_gsJson_TestProject.Test_RFC8259_Whitespace;
var
  s: string;
begin
  // Tab between tokens (RFC 8259 Section 2: ws = SP / HTAB / LF / CR)
  ljson.parse('{'#9'"a"'#9':'#9'"b"'#9'}');
  ljson.get('a', s);
  Assert.AreEqual('b', s, 'Tab whitespace between tokens failed');
  ljson.clear;
  // LF between tokens
  ljson.parse('{'#10'"a"'#10':'#10'"1"'#10'}');
  ljson.get('a', s);
  Assert.AreEqual('1', s, 'LF whitespace between tokens failed');
  ljson.clear;
  // CR+LF between tokens
  ljson.parse('{'#13#10'"a"'#13#10':'#13#10'"2"'#13#10'}');
  ljson.get('a', s);
  Assert.AreEqual('2', s, 'CRLF whitespace between tokens failed');
end;

{ RFC 8259 Section 4/5 - Deep Nesting }

procedure TgsJson_gsJson_TestProject.Test_RFC8259_DeepNesting;
var
  child1, child2, child3, child4: igsJson;
  v: integer;
begin
  ljson.parse('{"a":{"b":{"c":{"d":[1,2,[3,4]]}}}}');
  ljson.get('a', child1);
  Assert.IsTrue(child1.jsonType = TgsJsonElementType.etJson, 'a should be object');
  child1.get('b', child2);
  Assert.IsTrue(child2.jsonType = TgsJsonElementType.etJson, 'b should be object');
  child2.get('c', child3);
  Assert.IsTrue(child3.jsonType = TgsJsonElementType.etJson, 'c should be object');
  child3.get('d', child4);
  Assert.IsTrue(child4.jsonType = TgsJsonElementType.etJsonArray, 'd should be array');
  Assert.AreEqual(3, child4.jsonElementCount, 'd should have 3 elements');
  child4.get(0, v);
  Assert.AreEqual(1, v, 'First element should be 1');
end;

{ RFC 8259 Section 9 - Trailing Comma }

procedure TgsJson_gsJson_TestProject.Test_RFC8259_TrailingComma;
begin
  try
    ljson.parse('[1,2,3,]');
  except
    Log('RFC 8259: Correctly rejects trailing comma in array.');
    Assert.Pass;
    Exit;
  end;
  Log('WARNING - RFC 8259 Section 9: Parser accepts trailing comma. '
    + 'This is NOT valid JSON per the specification.');
  Assert.Pass;
end;

{ RFC 8259 Section 8 - UTF-8 Multibyte }

procedure TgsJson_gsJson_TestProject.Test_RFC8259_UTF8Multibyte;
var
  s: string;
  json: string;
begin
  json := '{"fr":"caf' + Char($00E9) + '","cn":"' + Char($4E16) + Char($754C) + '"}';
  ljson.parse(json);
  ljson.get('fr', s);
  Assert.IsTrue(Length(s) > 0, 'French accent string should not be empty');
  Assert.IsTrue(s = 'caf' + Char($00E9), 'French string mismatch');
  ljson.get('cn', s);
  Assert.IsTrue(Length(s) = 2, 'Chinese string should be 2 chars');
end;

procedure TgsJson_gsJson_TestProject.Test_Stringify;
const TEST_JSON='''
{
  "key0": "value0"
}
''';
var
 lStringified: string;
 lTest: boolean;
begin
  lJson := createJson().parse(TEST_JSON);
  lStringified := lJson.stringify;
  try
  lJson.get('key1', lTest);
  except
  end;
  Assert.AreEqual(lJson.stringify, lStringified);
end;


{ TgsJson_mcJson_TestProject }

procedure TgsJson_mcJson_TestProject.Setup;
begin
  ljson := CreateJson('mcjson');
end;

{ TgsJson_delphiJson_TestProject }

procedure TgsJson_embarcaderoDelphiJson_TestProject.Setup;
begin
  ljson := CreateJson('embarcaderoDelphiJson');
end;

{ TgsJson_beroJson_TestProject }

procedure TgsJson_beroJson_TestProject.Setup;
begin
  ljson := CreateJson('berojson');
end;

{ TgsJson_lkJson_TestProject }

procedure TgsJson_lkJson_TestProject.Setup;
begin
  ljson := CreateJson('lkjson');
end;

{ TgsJson_jsonDoc_TestProject }

procedure TgsJson_jsonDoc_TestProject.Setup;
begin
  ljson := CreateJson('jsondoc');
end;

{ TgsJson_jdo_TestProject }

procedure TgsJson_jdo_TestProject.Setup;
begin
  ljson := CreateJson('jdo');
end;

{ TgsJson_xSuperObject_TestProject }

procedure TgsJson_xSuperObject_TestProject.Setup;
begin
  ljson := CreateJson('xsuperobject');
end;

{ TgsJson_json4Delphi_TestProject }

procedure TgsJson_json4Delphi_TestProject.Setup;
begin
  ljson := CreateJson('json4delphi');
end;

{ TgsJson_superObject_TestProject }

procedure TgsJson_superObject_TestProject.Setup;
begin
  ljson := CreateJson('superobject');
end;

{ TgsJson_myJson_TestProject }

procedure TgsJson_myJson_TestProject.Setup;
begin
  ljson := CreateJson('myjson');
end;

{ TgsJson_chimera_TestProject }

procedure TgsJson_chimera_TestProject.Setup;
begin
  ljson := CreateJson('chimera');
end;

{ TgsJson_dwsJson_TestProject }

procedure TgsJson_dwsJson_TestProject.Setup;
begin
  ljson := CreateJson('dwsjson');
end;

{ TgsJson_dynamicDataObjects_TestProject }

procedure TgsJson_dynamicDataObjects_TestProject.Setup;
begin
  ljson := CreateJson('dynamicdataobjects');
end;

{ TgsJson_neslibJson_TestProject }

procedure TgsJson_neslibJson_TestProject.Setup;
begin
  ljson := CreateJson('neslibjson');
end;

{ TgsJson_grijjyBson_TestProject }

procedure TgsJson_grijjyBson_TestProject.Setup;
begin
  ljson := CreateJson('grijjybson');
end;

{ TgsJson_mormot2_TestProject }

procedure TgsJson_mormot2_TestProject.Setup;
begin
  ljson := CreateJson('mormot2');
end;

{ TgsJson_vsoftYaml_TestProject }

procedure TgsJson_vsoftYaml_TestProject.Setup;
begin
  ljson := CreateJson('vsoftyaml');
end;

procedure TgsJson_vsoftYaml_TestProject.Test_RFC8259_NumberInvalid(
  const aJson: string);
begin
  if aJson = '{"v":+1}' then
  begin
    Log('DISABLED - VSoft.YAML parser does not terminate when parsing {"v":+1} '
      + 'in JSON mode. The "+" prefix is NOT a valid number format per RFC 8259 '
      + 'Section 6. Test disabled due to near-infinite parse time in the YAML '
      + 'lexer/parser. The parser should reject "+1" but instead enters a very '
      + 'slow code path (backtracking or retry loop).');
    Assert.Fail('VSoft.YAML: Leading plus "{"v":+1}" causes parser hang - '
      + 'RFC 8259 Section 6 violation (not a valid number format)');
    Exit;
  end;
  inherited;
end;

initialization
  TDUnitX.RegisterTestFixture(TgsJson_gsJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_mcJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_embarcaderoDelphiJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_beroJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_lkJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_jsonDoc_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_jdo_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_xSuperObject_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_json4Delphi_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_superObject_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_myJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_chimera_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_dwsJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_dynamicDataObjects_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_neslibJson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_grijjyBson_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_mormot2_TestProject);
  TDUnitX.RegisterTestFixture(TgsJson_vsoftYaml_TestProject);

end.
