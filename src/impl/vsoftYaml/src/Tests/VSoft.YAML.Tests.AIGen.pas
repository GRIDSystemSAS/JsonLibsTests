unit VSoft.YAML.Tests.AIGen;

interface

uses
  DUnitX.TestFramework,
  VSoft.YAML.Types,
  System.SysUtils,
  System.Classes;

type
  [TestFixture]
  TYAMLParserTests = class
  private
    function CreateSimpleYAML: string;
    function CreateComplexYAML: string;
    function CreateSequenceYAML: string;
    function CreateMappingYAML: string;
    function CreateTypedValuesYAML: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    // Basic parsing tests
    [Test]
    procedure Test_LoadFromString_SimpleValue;
    [Test]
    procedure Test_LoadFromString_EmptyString;
    [Test]
    procedure Test_LoadFromString_InvalidYAML;

    // File and stream tests
//    [Test]
    procedure Test_LoadFromFile_ValidFile;
//    [Test]
    procedure Test_LoadFromFile_NonExistentFile;
//    [Test]
    procedure Test_LoadFromStream_ValidStream;
//    [Test]
    procedure Test_LoadFromStream_EmptyStream;

    // Type checking tests
    [Test]
    procedure Test_IsNull_TrueForNullValue;
    [Test]
    procedure Test_IsBoolean_TrueForBooleanValue;
    [Test]
    procedure Test_IsInteger_TrueForIntegerValue;
    [Test]
    procedure Test_IsFloat_TrueForFloatValue;
    [Test]
    procedure Test_IsString_TrueForStringValue;
    [Test]
    procedure Test_IsSequence_TrueForSequenceValue;
    [Test]
    procedure Test_IsMapping_TrueForMappingValue;
    [Test]
    procedure Test_IsTimeStamp_TrueForTimeStampValue;

    // Value conversion tests
    [Test]
    procedure Test_AsBoolean_ConvertsCorrectly;
    [Test]
    procedure Test_AsInteger_ConvertsCorrectly;
    [Test]
    procedure Test_AsFloat_ConvertsCorrectly;
    [Test]
    procedure Test_AsString_ConvertsCorrectly;
    [Test]
    procedure Test_AsDateTime_ConvertsCorrectly;

    // Sequence tests
    [Test]
    procedure Test_Sequence_Count;
    [Test]
    procedure Test_Sequence_Items;
    [Test]
    procedure Test_Sequence_AddValue_Boolean;
    [Test]
    procedure Test_Sequence_AddValue_Integer;
    [Test]
    procedure Test_Sequence_AddValue_String;
    [Test]
    procedure Test_Sequence_AddMapping;
    [Test]
    procedure Test_Sequence_AddSequence;

    // Mapping tests
    [Test]
    procedure Test_Mapping_Count;
    [Test]
    procedure Test_Mapping_Keys;
    [Test]
    procedure Test_Mapping_ContainsKey;
    [Test]
    procedure Test_Mapping_GetValue;
    [Test]
    procedure Test_Mapping_AddOrSetValue_Boolean;
    [Test]
    procedure Test_Mapping_AddOrSetValue_Integer;
    [Test]
    procedure Test_Mapping_AddOrSetValue_String;
    [Test]
    procedure Test_Mapping_AddOrSetSequence;
    [Test]
    procedure Test_Mapping_AddOrSetMapping;

    // JSONPath query tests
    [Test]
    procedure Test_QueryPath_SimpleProperty;
    [Test]
    procedure Test_QueryPath_NestedProperty;
    [Test]
    procedure Test_QueryPath_ArrayIndex;
    [Test]
    procedure Test_QueryPath_InvalidPath;

    // Edge cases and error handling
    [Test]
    procedure Test_AsBoolean_WithInvalidValue;
    [Test]
    procedure Test_AsInteger_WithInvalidValue;
    [Test]
    procedure Test_AsFloat_WithInvalidValue;
    [Test]
    procedure Test_GetNodes_WithInvalidIndex;
    [Test]
    procedure Test_GetValues_WithInvalidKey;

    // Complex structure tests
    [Test]
    procedure Test_ComplexYAML_Structure;
    [Test]
    procedure Test_NestedMappings;
    [Test]
    procedure Test_NestedSequences;
    [Test]
    procedure Test_MixedStructures;
  end;

implementation

uses
  System.DateUtils,
  VSoft.YAML; // Assuming this is where TYAMLReader is implemented

{ TYAMLParserTests }

procedure TYAMLParserTests.Setup;
begin
  // Setup code if needed
end;

procedure TYAMLParserTests.TearDown;
begin
  // Cleanup code if needed
end;

function TYAMLParserTests.CreateSimpleYAML: string;
begin
  Result := 'name: John Doe' + sLineBreak +
           'age: 30' + sLineBreak +
           'active: true';
end;

function TYAMLParserTests.CreateComplexYAML: string;
begin
  Result := 'person:' + sLineBreak +
           '  name: John Doe' + sLineBreak +
           '  age: 30' + sLineBreak +
           '  address:' + sLineBreak +
           '    street: 123 Main St' + sLineBreak +
           '    city: Anytown' + sLineBreak +
           '  hobbies:' + sLineBreak +
           '    - reading' + sLineBreak +
           '    - coding' + sLineBreak +
           '    - gaming';
end;

function TYAMLParserTests.CreateSequenceYAML: string;
begin
  Result := '- apple' + sLineBreak +
           '- banana' + sLineBreak +
           '- cherry';
end;

function TYAMLParserTests.CreateMappingYAML: string;
begin
  Result := 'key1: value1' + sLineBreak +
           'key2: value2' + sLineBreak +
           'key3: value3';
end;

function TYAMLParserTests.CreateTypedValuesYAML: string;
begin
  Result :=
           'null_value: null' + sLineBreak +
           'bool_true: true' + sLineBreak +
           'bool_false: false' + sLineBreak +
           'integer: 42' + sLineBreak +
           'float: 3.14' + sLineBreak +
           'string: "hello world"' + sLineBreak +
           'timestamp: 2023-12-01T10:30:00Z';
end;

// Basic parsing tests

procedure TYAMLParserTests.Test_LoadFromString_SimpleValue;
var
  yaml: IYAMLDocument;
begin
  yaml := TYAML.LoadFromString(CreateSimpleYAML);
  Assert.IsNotNull(yaml.Root);
  Assert.IsTrue(yaml.Root.IsMapping);
end;

procedure TYAMLParserTests.Test_LoadFromString_EmptyString;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('');
  Assert.IsNotNull(yaml);
end;

procedure TYAMLParserTests.Test_LoadFromString_InvalidYAML;
begin
  Assert.WillRaise(
    procedure
    begin
      TYAMLReader.LoadFromString('invalid: yaml: structure: [unclosed');
    end,
    EYAMLParseError
  );
end;

// File and stream tests

procedure TYAMLParserTests.Test_LoadFromFile_ValidFile;
var
  fileName: string;
  yaml: IYAMLValue;
  fileStream: TFileStream;
begin
  fileName := 'test.yml';
  fileStream := TFileStream.Create(fileName, fmCreate);
  try
    fileStream.WriteBuffer(CreateSimpleYAML[1], Length(CreateSimpleYAML) * SizeOf(Char));
  finally
    fileStream.Free;
  end;

  try
    yaml := TYAMLReader.LoadFromFile(fileName);
    Assert.IsNotNull(yaml);
    Assert.IsTrue(yaml.IsMapping);
  finally
    if FileExists(fileName) then
      DeleteFile(fileName);
  end;
end;

procedure TYAMLParserTests.Test_LoadFromFile_NonExistentFile;
begin
  Assert.WillRaise(
    procedure
    begin
      TYAMLReader.LoadFromFile('nonexistent.yml');
    end,
    Exception
  );
end;

procedure TYAMLParserTests.Test_LoadFromStream_ValidStream;
var
  stream: TStringStream;
  yaml: IYAMLValue;
begin
  stream := TStringStream.Create(CreateSimpleYAML);
  try
    yaml := TYAMLReader.LoadFromStream(stream);
    Assert.IsNotNull(yaml);
    Assert.IsTrue(yaml.IsMapping);
  finally
    stream.Free;
  end;
end;

procedure TYAMLParserTests.Test_LoadFromStream_EmptyStream;
var
  stream: TStringStream;
  yaml: IYAMLValue;
begin
  stream := TStringStream.Create('');
  try
    yaml := TYAMLReader.LoadFromStream(stream);
    Assert.IsNotNull(yaml);
  finally
    stream.Free;
  end;
end;

// Type checking tests

procedure TYAMLParserTests.Test_IsNull_TrueForNullValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['null_value'].IsNull);
end;

procedure TYAMLParserTests.Test_IsBoolean_TrueForBooleanValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['bool_true'].IsBoolean);
  Assert.IsTrue(yaml.Values['bool_false'].IsBoolean);
end;

procedure TYAMLParserTests.Test_IsInteger_TrueForIntegerValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['integer'].IsInteger);
end;

procedure TYAMLParserTests.Test_IsFloat_TrueForFloatValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['float'].IsFloat);
end;

procedure TYAMLParserTests.Test_IsString_TrueForStringValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['string'].IsString);
end;

procedure TYAMLParserTests.Test_IsSequence_TrueForSequenceValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateSequenceYAML);
  Assert.IsTrue(yaml.IsSequence);
end;

procedure TYAMLParserTests.Test_IsMapping_TrueForMappingValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateMappingYAML);
  Assert.IsTrue(yaml.IsMapping);
end;

procedure TYAMLParserTests.Test_IsTimeStamp_TrueForTimeStampValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['timestamp'].IsTimeStamp);
end;

// Value conversion tests

procedure TYAMLParserTests.Test_AsBoolean_ConvertsCorrectly;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.IsTrue(yaml.Values['bool_true'].AsBoolean);
  Assert.IsFalse(yaml.Values['bool_false'].AsBoolean);
end;

procedure TYAMLParserTests.Test_AsInteger_ConvertsCorrectly;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.AreEqual(42, yaml.Values['integer'].AsInteger);
end;

procedure TYAMLParserTests.Test_AsFloat_ConvertsCorrectly;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.AreEqual(3.14, yaml.Values['float'].AsFloat, 0.001);
end;

procedure TYAMLParserTests.Test_AsString_ConvertsCorrectly;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  Assert.AreEqual('hello world', yaml.Values['string'].AsString);
end;

procedure TYAMLParserTests.Test_AsDateTime_ConvertsCorrectly;
var
  yaml: IYAMLValue;
  expectedDate: TDateTime;
begin
  yaml := TYAMLReader.LoadFromString(CreateTypedValuesYAML);
  expectedDate := EncodeDateTime(2023, 12, 1, 10, 30, 0, 0);
  Assert.AreEqual(expectedDate, yaml.Values['timestamp'].AsUTCDateTime, 1 / (24 * 60)); // 1 minute tolerance
end;

// Sequence tests

procedure TYAMLParserTests.Test_Sequence_Count;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
begin
  yaml := TYAMLReader.LoadFromString(CreateSequenceYAML);
  sequence := yaml.AsSequence;
  Assert.AreEqual(3, sequence.Count);
end;

procedure TYAMLParserTests.Test_Sequence_Items;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
begin
  yaml := TYAMLReader.LoadFromString(CreateSequenceYAML);
  sequence := yaml.AsSequence;
  Assert.AreEqual('apple', sequence.Items[0].AsString);
  Assert.AreEqual('banana', sequence.Items[1].AsString);
  Assert.AreEqual('cherry', sequence.Items[2].AsString);
end;

procedure TYAMLParserTests.Test_Sequence_AddValue_Boolean;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
  newValue: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('[]');
  sequence := yaml.AsSequence;
  newValue := sequence.AddValue(True);
  Assert.IsTrue(newValue.AsBoolean);
  Assert.AreEqual(1, sequence.Count);
end;

procedure TYAMLParserTests.Test_Sequence_AddValue_Integer;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
  newValue: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('[]');
  sequence := yaml.AsSequence;
  newValue := sequence.AddValue(42);
  Assert.AreEqual(42, newValue.AsInteger);
  Assert.AreEqual(1, sequence.Count);
end;

procedure TYAMLParserTests.Test_Sequence_AddValue_String;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
  newValue: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('[]');
  sequence := yaml.AsSequence;
  newValue := sequence.AddValue('test');
  Assert.AreEqual('test', newValue.AsString);
  Assert.AreEqual(1, sequence.Count);
end;

procedure TYAMLParserTests.Test_Sequence_AddMapping;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
  mapping: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString('[]');
  sequence := yaml.AsSequence;
  mapping := sequence.AddMapping;
  Assert.IsNotNull(mapping);
  Assert.IsTrue(mapping.IsMapping);
  Assert.AreEqual(1, sequence.Count);
end;

procedure TYAMLParserTests.Test_Sequence_AddSequence;
var
  yaml: IYAMLValue;
  sequence: IYAMLSequence;
  nestedSequence: IYAMLSequence;
begin
  yaml := TYAMLReader.LoadFromString('[]');
  sequence := yaml.AsSequence;
  nestedSequence := sequence.AddSequence;
  Assert.IsNotNull(nestedSequence);
  Assert.IsTrue(nestedSequence.IsSequence);
  Assert.AreEqual(1, sequence.Count);
end;

// Mapping tests

procedure TYAMLParserTests.Test_Mapping_Count;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString(CreateMappingYAML);
  mapping := yaml.AsMapping;
  Assert.AreEqual(3, mapping.Count);
end;

procedure TYAMLParserTests.Test_Mapping_Keys;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString(CreateMappingYAML);
  mapping := yaml.AsMapping;
  Assert.AreEqual('key1', mapping.Keys[0]);
  Assert.AreEqual('key2', mapping.Keys[1]);
  Assert.AreEqual('key3', mapping.Keys[2]);
end;

procedure TYAMLParserTests.Test_Mapping_ContainsKey;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString(CreateMappingYAML);
  mapping := yaml.AsMapping;
  Assert.IsTrue(mapping.ContainsKey('key1'));
  Assert.IsTrue(mapping.ContainsKey('key2'));
  Assert.IsTrue(mapping.ContainsKey('key3'));
  Assert.IsFalse(mapping.ContainsKey('nonexistent'));
end;

procedure TYAMLParserTests.Test_Mapping_GetValue;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString(CreateMappingYAML);
  mapping := yaml.AsMapping;
  Assert.AreEqual('value1', mapping.Items['key1'].AsString);
  Assert.AreEqual('value2', mapping.Items['key2'].AsString);
  Assert.AreEqual('value3', mapping.Items['key3'].AsString);
end;

procedure TYAMLParserTests.Test_Mapping_AddOrSetValue_Boolean;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
  newValue: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('{}');
  mapping := yaml.AsMapping;
  newValue := mapping.AddOrSetValue('test_bool', True);
  Assert.IsTrue(newValue.AsBoolean);
  Assert.IsTrue(mapping.ContainsKey('test_bool'));
end;

procedure TYAMLParserTests.Test_Mapping_AddOrSetValue_Integer;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
  newValue: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('{}');
  mapping := yaml.AsMapping;
  newValue := mapping.AddOrSetValue('test_int', 42);
  Assert.AreEqual(42, newValue.AsInteger);
  Assert.IsTrue(mapping.ContainsKey('test_int'));
end;

procedure TYAMLParserTests.Test_Mapping_AddOrSetValue_String;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
  newValue: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('{}');
  mapping := yaml.AsMapping;
  newValue := mapping.AddOrSetValue('test_string', 'hello');
  Assert.AreEqual('hello', newValue.AsString);
  Assert.IsTrue(mapping.ContainsKey('test_string'));
end;

procedure TYAMLParserTests.Test_Mapping_AddOrSetSequence;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
  sequence: IYAMLSequence;
begin
  yaml := TYAMLReader.LoadFromString('{}');
  mapping := yaml.AsMapping;
  sequence := mapping.AddOrSetSequence('test_sequence');
  Assert.IsNotNull(sequence);
  Assert.IsTrue(sequence.IsSequence);
  Assert.IsTrue(mapping.ContainsKey('test_sequence'));
end;

procedure TYAMLParserTests.Test_Mapping_AddOrSetMapping;
var
  yaml: IYAMLValue;
  mapping: IYAMLMapping;
  nestedMapping: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString('{}');
  mapping := yaml.AsMapping;
  nestedMapping := mapping.AddOrSetMapping('test_mapping');
  Assert.IsNotNull(nestedMapping);
  Assert.IsTrue(nestedMapping.IsMapping);
  Assert.IsTrue(mapping.ContainsKey('test_mapping'));
end;

// JSONPath query tests

procedure TYAMLParserTests.Test_QueryPath_SimpleProperty;
var
  yaml: IYAMLValue;
  result: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateSimpleYAML);
  result := yaml.QueryPath('name');
  Assert.IsNotNull(result);
  Assert.AreEqual('John Doe', result.AsString);
end;

procedure TYAMLParserTests.Test_QueryPath_NestedProperty;
var
  yaml: IYAMLValue;
  result: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateComplexYAML);
  result := yaml.QueryPath('person.name');
  Assert.IsNotNull(result);
  Assert.AreEqual('John Doe', result.AsString);
end;

procedure TYAMLParserTests.Test_QueryPath_ArrayIndex;
var
  yaml: IYAMLValue;
  result: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateComplexYAML);
  result := yaml.QueryPath('person.hobbies[0]');
  Assert.IsNotNull(result);
  Assert.AreEqual('reading', result.AsString);
end;

procedure TYAMLParserTests.Test_QueryPath_InvalidPath;
var
  yaml: IYAMLValue;
  result: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateSimpleYAML);
  result := yaml.QueryPath('nonexistent.path');
  Assert.AreEqual(TYAMLValueType.vtNull, result.ValueType);
end;

// Error handling tests

procedure TYAMLParserTests.Test_AsBoolean_WithInvalidValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('test: "not a boolean"');
  Assert.WillRaise(
    procedure
    begin
      yaml.Values['test'].AsBoolean;
    end,
    Exception
  );
end;

procedure TYAMLParserTests.Test_AsInteger_WithInvalidValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('test: "not an integer"');
  Assert.WillRaise(
    procedure
    begin
      yaml.Values['test'].AsInteger;
    end,
    Exception
  );
end;

procedure TYAMLParserTests.Test_AsFloat_WithInvalidValue;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString('test: "not a float"');
  Assert.WillRaise(
    procedure
    begin
      yaml.Values['test'].AsFloat;
    end,
    Exception
  );
end;

procedure TYAMLParserTests.Test_GetNodes_WithInvalidIndex;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateSequenceYAML);
  Assert.AreEqual(TYAMLValueType.vtNull, yaml.Nodes[99].ValueType );
end;

procedure TYAMLParserTests.Test_GetValues_WithInvalidKey;
var
  yaml: IYAMLValue;
  result: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateSimpleYAML);
  result := yaml.Values['nonexistent_key'];
  Assert.AreEqual(TYAMLValueType.vtNull, result.ValueType);
end;

// Complex structure tests

procedure TYAMLParserTests.Test_ComplexYAML_Structure;
var
  yaml: IYAMLValue;
begin
  yaml := TYAMLReader.LoadFromString(CreateComplexYAML);
  Assert.IsTrue(yaml.IsMapping);
  Assert.IsTrue(yaml.Values['person'].IsMapping);
  Assert.AreEqual('John Doe', yaml.Values['person'].Values['name'].AsString);
  Assert.AreEqual(30, yaml.Values['person'].Values['age'].AsInteger);
  Assert.IsTrue(yaml.Values['person'].Values['address'].IsMapping);
  Assert.IsTrue(yaml.Values['person'].Values['hobbies'].IsSequence);
end;

procedure TYAMLParserTests.Test_NestedMappings;
var
  yaml: IYAMLValue;
  person, address: IYAMLMapping;
begin
  yaml := TYAMLReader.LoadFromString(CreateComplexYAML);
  person := yaml.Values['person'].AsMapping;
  address := person.Items['address'].AsMapping;

  Assert.AreEqual('123 Main St', address.Items['street'].AsString);
  Assert.AreEqual('Anytown', address.Items['city'].AsString);
end;

procedure TYAMLParserTests.Test_NestedSequences;
var
  yaml: IYAMLValue;
  hobbies: IYAMLSequence;
begin
  yaml := TYAMLReader.LoadFromString(CreateComplexYAML);
  hobbies := yaml.Values['person'].Values['hobbies'].AsSequence;

  Assert.AreEqual(3, hobbies.Count);
  Assert.AreEqual('reading', hobbies.Items[0].AsString);
  Assert.AreEqual('coding', hobbies.Items[1].AsString);
  Assert.AreEqual('gaming', hobbies.Items[2].AsString);
end;

procedure TYAMLParserTests.Test_MixedStructures;
var
  yamlContent: string;
  yaml: IYAMLValue;
  root: IYAMLMapping;
  users: IYAMLSequence;
  firstUser: IYAMLMapping;
begin
  yamlContent := 'users:' + sLineBreak +
                '  - name: Alice' + sLineBreak +
                '    roles:' + sLineBreak +
                '      - admin' + sLineBreak +
                '      - user' + sLineBreak +
                '  - name: Bob' + sLineBreak +
                '    roles:' + sLineBreak +
                '      - user' + sLineBreak +
                'config:' + sLineBreak +
                '  debug: true' + sLineBreak +
                '  timeout: 30';

  yaml := TYAMLReader.LoadFromString(yamlContent);
  root := yaml.AsMapping;

  users := root.Items['users'].AsSequence;
  Assert.AreEqual(2, users.Count);

  firstUser := users.Items[0].AsMapping;
  Assert.AreEqual('Alice', firstUser.Items['name'].AsString);
  Assert.AreEqual(2, firstUser.Items['roles'].AsSequence.Count);

  Assert.IsTrue(root.Items['config'].Values['debug'].AsBoolean);
  Assert.AreEqual(30, root.Items['config'].Values['timeout'].AsInteger);
end;

initialization
  TDUnitX.RegisterTestFixture(TYAMLParserTests);

end.
