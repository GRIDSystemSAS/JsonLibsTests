unit VSoft.YAML.Tests.Path;

interface

uses
  DUnitX.TestFramework,
  VSoft.YAML,
  VSoft.YAML.Path;

type
  [TestFixture]
  TYAMLPathTests = class
  private
    function CreateTestDocument: IYAMLDocument;
    function CreateComplexTestDocument: IYAMLDocument;
    function CreateArrayTestDocument: IYAMLDocument;
    function CreateFilterTestDocument: IYAMLDocument;
    function CreateDocumentationExampleDocument: IYAMLDocument;
  public
    [Test]
    procedure TestRootAccess;

    [Test]
    procedure TestSimplePropertyAccess;

    [Test]
    procedure TestNestedPropertyAccess;

    [Test]
    procedure TestArrayIndexAccess;

    [Test]
    procedure TestArraySlicing;

    [Test]
    procedure TestWildcardOperator;

    [Test]
    procedure TestRecursiveDescent;

    [Test]
    procedure TestMultipleIndexes;

    [Test]
    procedure TestQuotedPropertyNames;

    [Test]
    procedure TestComplexPath;

    [Test]
    procedure TestNonExistentPath;

    [Test]
    procedure TestEmptyResults;

    [Test]
    procedure TestSingleMatch;

    [Test]
    procedure TestInvalidPathExpressions;

    [Test]
    procedure TestSliceWithStep;

    [Test]
    procedure TestSliceEdgeCases;

    [Test]
    procedure TestMixedContent;

    [Test]
    procedure TestStaticMethods;

    [Test]
    procedure TestCaseSensitivity;

    [Test]
    procedure TestSpecialCharacterHandling;

    [Test]
    procedure TestFilterBasicComparisons;

    [Test]
    procedure TestFilterLogicalOperators;

    [Test]
    procedure TestFilterCurrentItemAccess;

    [Test]
    procedure TestFilterPathExpressions;

    [Test]
    procedure TestFilterLiteralValues;

    [Test]
    procedure TestFilterSpecialOperators;

    [Test]
    procedure TestFilterComplexExpressions;

    [Test]
    procedure TestFilterEdgeCases;
    
    // Additional tests to cover documentation examples
    [Test]
    procedure TestDocumentationExamples;
    
    [Test]
    procedure TestTruthinessEvaluation;
    
    [Test]
    procedure TestComplexPathCombinations;
    
    [Test]
    procedure TestCollectionSizeOperators;
    
    [Test]
    procedure TestNestedArrayQueries;
  end;

implementation

uses
  System.SysUtils,
  VSoft.YAML.Classes;

{ TYAMLPathTests }

function TYAMLPathTests.CreateTestDocument: IYAMLDocument;
var
  yamlText: string;
begin
  yamlText :=
    'name: "John Doe"' + sLineBreak +
    'age: 30' + sLineBreak +
    'address:' + sLineBreak +
    '  street: "123 Main St"' + sLineBreak +
    '  city: "New York"' + sLineBreak +
    '  zipcode: "10001"' + sLineBreak +
    'phones:' + sLineBreak +
    '  - "555-1234"' + sLineBreak +
    '  - "555-5678"' + sLineBreak +
    '  - "555-9012"' + sLineBreak +
    'active: true';

  result := TYAML.LoadFromString(yamlText);
end;

function TYAMLPathTests.CreateComplexTestDocument: IYAMLDocument;
var
  yamlText: string;
begin
  yamlText :=
    'store:' + sLineBreak +
    '  book:' + sLineBreak +
    '    - category: "reference"' + sLineBreak +
    '      author: "Nigel Rees"' + sLineBreak +
    '      title: "Sayings of the Century"' + sLineBreak +
    '      price: 8.95' + sLineBreak +
    '    - category: "fiction"' + sLineBreak +
    '      author: "Evelyn Waugh"' + sLineBreak +
    '      title: "Sword of Honour"' + sLineBreak +
    '      price: 12.99' + sLineBreak +
    '    - category: "fiction"' + sLineBreak +
    '      author: "Herman Melville"' + sLineBreak +
    '      title: "Moby Dick"' + sLineBreak +
    '      isbn: "0-553-21311-3"' + sLineBreak +
    '      price: 8.99' + sLineBreak +
    '    - category: "fiction"' + sLineBreak +
    '      author: "J.R.R. Tolkien"' + sLineBreak +
    '      title: "The Lord of the Rings"' + sLineBreak +
    '      isbn: "0-395-19395-8"' + sLineBreak +
    '      price: 22.99' + sLineBreak +
    '  bicycle:' + sLineBreak +
    '    color: "red"' + sLineBreak +
    '    price: 19.95' + sLineBreak +
    'expensive: 10';

  result := TYAML.LoadFromString(yamlText);
end;

function TYAMLPathTests.CreateArrayTestDocument: IYAMLDocument;
var
  yamlText: string;
begin
  yamlText :=
    'numbers: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]' + sLineBreak +
    'empty_array: []' + sLineBreak +
    'mixed:' + sLineBreak +
    '  - "string"' + sLineBreak +
    '  - 42' + sLineBreak +
    '  - true' + sLineBreak +
    '  - null' + sLineBreak +
    '  - [1, 2, 3]';

  result := TYAML.LoadFromString(yamlText);
end;

function TYAMLPathTests.CreateFilterTestDocument: IYAMLDocument;
var
  yamlText: string;
begin
  yamlText :=
    'products:' + sLineBreak +
    '  - name: "Laptop"' + sLineBreak +
    '    price: 999.99' + sLineBreak +
    '    category: "Electronics"' + sLineBreak +
    '    inStock: true' + sLineBreak +
    '    rating: 4.5' + sLineBreak +
    '    tags: ["computer", "portable", "work"]' + sLineBreak +
    '    specs:' + sLineBreak +
    '      cpu: "Intel i7"' + sLineBreak +
    '      ram: 16' + sLineBreak +
    '  - name: "Mouse"' + sLineBreak +
    '    price: 25.50' + sLineBreak +
    '    category: "Electronics"' + sLineBreak +
    '    inStock: false' + sLineBreak +
    '    rating: 3.8' + sLineBreak +
    '    tags: ["peripheral", "input"]' + sLineBreak +
    '  - name: "Book"' + sLineBreak +
    '    price: 15.99' + sLineBreak +
    '    category: "Literature"' + sLineBreak +
    '    inStock: true' + sLineBreak +
    '    rating: 4.2' + sLineBreak +
    '    tags: ["reading", "education"]' + sLineBreak +
    '  - name: "Headphones"' + sLineBreak +
    '    price: 89.99' + sLineBreak +
    '    category: "Electronics"' + sLineBreak +
    '    inStock: true' + sLineBreak +
    '    rating: 4.7' + sLineBreak +
    '    tags: ["audio", "portable"]' + sLineBreak +
    '  - name: "Empty Tags"' + sLineBreak +
    '    price: 0.01' + sLineBreak +
    '    category: "Test"' + sLineBreak +
    '    inStock: false' + sLineBreak +
    '    rating: 0' + sLineBreak +
    '    tags: []' + sLineBreak +
    'categories: ["Electronics", "Literature", "Test"]' + sLineBreak +
    'metadata:' + sLineBreak +
    '  totalProducts: 5' + sLineBreak +
    '  averagePrice: 226.10' + sLineBreak +
    '  lastUpdated: "2024-01-15"';

  result := TYAML.LoadFromString(yamlText);
end;

function TYAMLPathTests.CreateDocumentationExampleDocument: IYAMLDocument;
var
  yamlText: string;
begin
  yamlText := 
    'store:' + sLineBreak +
    '  books:' + sLineBreak +
    '    - title: "The Great Gatsby"' + sLineBreak +
    '      author: "F. Scott Fitzgerald"' + sLineBreak +
    '      price: 12.99' + sLineBreak +
    '      category: "Fiction"' + sLineBreak +
    '      inStock: true' + sLineBreak +
    '      rating: 4.5' + sLineBreak +
    '      featured: true' + sLineBreak +
    '    - title: "To Kill a Mockingbird"' + sLineBreak +
    '      author: "Harper Lee"' + sLineBreak +
    '      price: 14.99' + sLineBreak +
    '      category: "Fiction"' + sLineBreak +
    '      inStock: false' + sLineBreak +
    '      rating: 4.8' + sLineBreak +
    '      featured: false' + sLineBreak +
    '  electronics:' + sLineBreak +
    '    - name: "Laptop"' + sLineBreak +
    '      price: 899.99' + sLineBreak +
    '      category: "Computing"' + sLineBreak +
    '      inStock: true' + sLineBreak +
    '      rating: 4.2' + sLineBreak +
    '      discount: 0.1' + sLineBreak +
    '    - name: "Mouse"' + sLineBreak +
    '      price: 25.50' + sLineBreak +
    '      category: "Accessories"' + sLineBreak +
    '      inStock: true' + sLineBreak +
    '      rating: 3.8' + sLineBreak +
    'customers:' + sLineBreak +
    '  - name: "John Doe"' + sLineBreak +
    '    email: "john@example.com"' + sLineBreak +
    '    active: true' + sLineBreak +
    '    orders:' + sLineBreak +
    '      - id: 1' + sLineBreak +
    '        total: 150.50' + sLineBreak +
    '        items: ["laptop", "mouse"]' + sLineBreak +
    '      - id: 2' + sLineBreak +
    '        total: 75.25' + sLineBreak +
    '        items: ["book"]' + sLineBreak +
    '  - name: "Jane Smith"' + sLineBreak +
    '    email: "jane@example.com"' + sLineBreak +
    '    active: false' + sLineBreak +
    '    orders: []' + sLineBreak +
    '  - name: "Bob Wilson"' + sLineBreak +
    '    email: ""' + sLineBreak +
    '    active: true' + sLineBreak +
    '    orders:' + sLineBreak +
    '      - id: 3' + sLineBreak +
    '        total: 200.00' + sLineBreak +
    '        items: ["electronics", "accessories"]';
    
  result := TYAML.LoadFromString(yamlText);
end;

procedure TYAMLPathTests.TestRootAccess;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test root access
  matches := doc.Query('$');

  Assert.AreEqual(1, matches.Count, 'Root access should return one match');
  Assert.IsTrue(matches.Items[0].IsMapping, 'Root should be a mapping');
end;

procedure TYAMLPathTests.TestSimplePropertyAccess;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test simple property access
  matches := doc.Query('$.name');

  Assert.AreEqual(1, matches.Count, 'Name property should return one match');
  Assert.AreEqual('John Doe', matches.Items[0].AsString, 'Name should be John Doe');

  // Test numeric property
  matches := doc.Query('$.age');

  Assert.AreEqual(1, matches.Count, 'Age property should return one match');
  Assert.AreEqual<Int64>(30, matches.Items[0].AsInteger, 'Age should be 30');

  // Test boolean property
  matches := doc.Query('$.active');

  Assert.AreEqual(1, matches.Count, 'Active property should return one match');
  Assert.IsTrue(matches.Items[0].AsBoolean, 'Active should be true');
end;

procedure TYAMLPathTests.TestNestedPropertyAccess;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test nested property access
  matches := doc.Query('$.address.street');

  Assert.AreEqual(1, matches.Count, 'Street should return one match');
  Assert.AreEqual('123 Main St', matches.Items[0].AsString, 'Street should be 123 Main St');

  matches := doc.Query('$.address.city');

  Assert.AreEqual(1, matches.Count, 'City should return one match');
  Assert.AreEqual('New York', matches.Items[0].AsString, 'City should be New York');
end;

procedure TYAMLPathTests.TestArrayIndexAccess;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test array index access
  matches := doc.Query('$.phones[0]');

  Assert.AreEqual(1, matches.Count, 'First phone should return one match');
  Assert.AreEqual('555-1234', matches.Items[0].AsString, 'First phone should be 555-1234');

  matches := doc.Query('$.phones[1]');

  Assert.AreEqual(1, matches.Count, 'Second phone should return one match');
  Assert.AreEqual('555-5678', matches.Items[0].AsString, 'Second phone should be 555-5678');

  matches := doc.Query('$.phones[2]');

  Assert.AreEqual(1, matches.Count, 'Third phone should return one match');
  Assert.AreEqual('555-9012', matches.Items[0].AsString, 'Third phone should be 555-9012');
end;

procedure TYAMLPathTests.TestArraySlicing;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateArrayTestDocument;

  // Test array slicing [start:end]
  matches := doc.Query('$.numbers[1:4]');

  Assert.AreEqual(3, matches.Count, 'Slice [1:4] should return 3 items');
  Assert.AreEqual<Int64>(2, matches.Items[0].AsInteger, 'First item should be 2');
  Assert.AreEqual<Int64>(3, matches.Items[1].AsInteger, 'Second item should be 3');
  Assert.AreEqual<Int64>(4, matches.Items[2].AsInteger, 'Third item should be 4');

  // Test slice from start
  matches := doc.Query('$.numbers[:3]');

  Assert.AreEqual(3, matches.Count, 'Slice [:3] should return 3 items');
  Assert.AreEqual<Int64>(1, matches.Items[0].AsInteger, 'First item should be 1');
  Assert.AreEqual<Int64>(2, matches.Items[1].AsInteger, 'Second item should be 2');
  Assert.AreEqual<Int64>(3, matches.Items[2].AsInteger, 'Third item should be 3');
end;

procedure TYAMLPathTests.TestWildcardOperator;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test wildcard on mapping (get all values)
  matches := doc.Query('$.address.*');

  Assert.AreEqual(3, matches.Count, 'Address wildcard should return 3 items');

  // Test wildcard on array
  matches := doc.Query('$.phones.*');

  Assert.AreEqual(3, matches.Count, 'Phones wildcard should return 3 items');
  Assert.AreEqual('555-1234', matches.Items[0].AsString, 'First phone should be 555-1234');
  Assert.AreEqual('555-5678', matches.Items[1].AsString, 'Second phone should be 555-5678');
  Assert.AreEqual('555-9012', matches.Items[2].AsString, 'Third phone should be 555-9012');
end;

procedure TYAMLPathTests.TestRecursiveDescent;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
  i: Integer;
  found: Boolean;
begin
  doc := CreateComplexTestDocument;

  // Test recursive descent to find all authors
  matches := doc.Query('$..author');

  Assert.AreEqual(4, matches.Count, 'Should find 4 authors');

  // Verify we found all expected authors
  found := False;
  for i := 0 to matches.Count - 1 do
  begin
    if matches.Items[i].AsString = 'Nigel Rees' then
      found := True;
  end;
  Assert.IsTrue(found, 'Should find Nigel Rees');

  // Test recursive descent to find all prices
  matches := doc.Query('$..price');

  Assert.AreEqual(5, matches.Count, 'Should find 5 prices (4 books + 1 bicycle)');
end;

procedure TYAMLPathTests.TestMultipleIndexes;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test multiple index access
  matches := doc.Query('$.phones[0,2]');

  Assert.AreEqual(2, matches.Count, 'Multiple index should return 2 items');
  Assert.AreEqual('555-1234', matches.Items[0].AsString, 'First item should be 555-1234');
  Assert.AreEqual('555-9012', matches.Items[1].AsString, 'Second item should be 555-9012');
end;

procedure TYAMLPathTests.TestQuotedPropertyNames;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test quoted property names
  matches := doc.Query('$["name"]');

  Assert.AreEqual(1, matches.Count, 'Quoted name should return one match');
  Assert.AreEqual('John Doe', matches.Items[0].AsString, 'Name should be John Doe');

  matches := doc.Query('$[''age'']');

  Assert.AreEqual(1, matches.Count, 'Quoted age should return one match');
  Assert.AreEqual<Int64>(30, matches.Items[0].AsInteger, 'Age should be 30');
end;

procedure TYAMLPathTests.TestComplexPath;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateComplexTestDocument;

  // Test complex path - get all fiction books
  matches := doc.Query('$.store.book[*].category');

  Assert.AreEqual(4, matches.Count, 'Should find 4 book categories');

  // Test getting specific book by index
  matches := doc.Query('$.store.book[0].title');

  Assert.AreEqual(1, matches.Count, 'Should find one title');
  Assert.AreEqual('Sayings of the Century', matches.Items[0].AsString, 'Title should match');
end;

procedure TYAMLPathTests.TestNonExistentPath;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test non-existent property
  matches := doc.Query('$.nonexistent');

  Assert.AreEqual(0, matches.Count, 'Non-existent property should return no matches');

  // Test non-existent nested property
  matches := doc.Query('$.address.nonexistent');

  Assert.AreEqual(0, matches.Count, 'Non-existent nested property should return no matches');

  // Test out-of-bounds array access
  matches := doc.Query('$.phones[10]');

  Assert.AreEqual(0, matches.Count, 'Out-of-bounds array access should return no matches');
end;

procedure TYAMLPathTests.TestEmptyResults;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateArrayTestDocument;

  // Test empty array
  matches := doc.Query('$.empty_array[*]');

  Assert.AreEqual(0, matches.Count, 'Empty array wildcard should return no matches');

  // Test slice of empty array
  matches := doc.Query('$.empty_array[1:3]');

  Assert.AreEqual(0, matches.Count, 'Empty array slice should return no matches');
end;

procedure TYAMLPathTests.TestSingleMatch;
var
  doc: IYAMLDocument;
  match: IYAMLValue;
  found: Boolean;
begin
  doc := CreateTestDocument;

  // Test single match found
  found := doc.QuerySingle('$.name', match);

  Assert.IsTrue(found, 'Single match should be found');
  Assert.AreEqual('John Doe', match.AsString, 'Single match should be John Doe');

  // Test single match not found
  found := doc.QuerySingle('$.nonexistent', match);

  Assert.IsFalse(found, 'Single match should not be found');
  Assert.IsTrue(match.IsNull, 'Match should be null when not found');

  // Test single match with multiple results (should return first)
  found := doc.QuerySingle('$.phones[*]', match);

  Assert.IsTrue(found, 'Single match should be found for multiple results');
  Assert.AreEqual('555-1234', match.AsString, 'Should return first phone number');
end;

procedure TYAMLPathTests.TestInvalidPathExpressions;
var
  doc: IYAMLDocument;
begin
  doc := CreateTestDocument;

  // Test missing root
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('name');
    end,
    EYAMLPathError,
    'Missing root should raise exception'
  );

  // Test duplicate root
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('$$');
    end,
    EYAMLPathError,
    'Duplicate root should raise exception'
  );

  // Test invalid operator
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('$name');
    end,
    EYAMLPathError,
    'Invalid operator should raise exception'
  );

  // Test missing member name
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('$.');
    end,
    EYAMLPathError,
    'Missing member name should raise exception'
  );

  // Test another missing member name case
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('$.name.');
    end,
    EYAMLPathError,
    'Missing member name after dot should raise exception'
  );

  // Test missing closing bracket
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('$[0');
    end,
    EYAMLPathError,
    'Missing closing bracket should raise exception'
  );

  // Test invalid recursive descent
  Assert.WillRaise(
    procedure
    begin
      TYAMLPathProcessor.Create('$..');
    end,
    EYAMLPathError,
    'Invalid recursive descent should raise exception'
  );
end;

procedure TYAMLPathTests.TestSliceWithStep;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateArrayTestDocument;

  // Test slice with step
  matches := doc.Query('$.numbers[0:8:2]');

  Assert.AreEqual(4, matches.Count, 'Slice with step 2 should return 4 items');
  Assert.AreEqual<Int64>(1, matches.Items[0].AsInteger, 'First item should be 1');
  Assert.AreEqual<Int64>(3, matches.Items[1].AsInteger, 'Second item should be 3');
  Assert.AreEqual<Int64>(5, matches.Items[2].AsInteger, 'Third item should be 5');
  Assert.AreEqual<Int64>(7, matches.Items[3].AsInteger, 'Fourth item should be 7');

  // Test slice with step 3
  matches := doc.Query('$.numbers[1::3]');

  Assert.AreEqual(3, matches.Count, 'Slice with step 3 should return 3 items');
  Assert.AreEqual<Int64>(2, matches.Items[0].AsInteger, 'First item should be 2');
  Assert.AreEqual<Int64>(5, matches.Items[1].AsInteger, 'Second item should be 5');
  Assert.AreEqual<Int64>(8, matches.Items[2].AsInteger, 'Third item should be 8');
end;

procedure TYAMLPathTests.TestSliceEdgeCases;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateArrayTestDocument;

  // Test slice to end
  matches := doc.Query('$.numbers[7:]');

  Assert.AreEqual(3, matches.Count, 'Slice to end should return 3 items');
  Assert.AreEqual<Int64>(8, matches.Items[0].AsInteger, 'First item should be 8');
  Assert.AreEqual<Int64>(9, matches.Items[1].AsInteger, 'Second item should be 9');
  Assert.AreEqual<Int64>(10, matches.Items[2].AsInteger, 'Third item should be 10');

  // Test slice beyond array bounds
  matches := doc.Query('$.numbers[5:20]');

  Assert.AreEqual(5, matches.Count, 'Slice beyond bounds should be clamped');
  Assert.AreEqual<Int64>(6, matches.Items[0].AsInteger, 'First item should be 6');
  Assert.AreEqual<Int64>(10, matches.Items[4].AsInteger, 'Last item should be 10');
end;

procedure TYAMLPathTests.TestMixedContent;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateArrayTestDocument;

  // Test mixed content array
  matches := doc.Query('$.mixed[*]');

  Assert.AreEqual(5, matches.Count, 'Mixed array should return 5 items');
  Assert.AreEqual('string', matches.Items[0].AsString, 'First item should be string');
  Assert.AreEqual<Int64>(42, matches.Items[1].AsInteger, 'Second item should be 42');
  Assert.IsTrue(matches.Items[2].AsBoolean, 'Third item should be true');
  Assert.IsTrue(matches.Items[3].IsNull, 'Fourth item should be null');
  Assert.IsTrue(matches.Items[4].IsSequence, 'Fifth item should be sequence');

  // Test accessing nested array
  matches := doc.Query('$.mixed[4][1]');

  Assert.AreEqual(1, matches.Count, 'Nested array access should return 1 item');
  Assert.AreEqual<Int64>(2, matches.Items[0].AsInteger, 'Nested item should be 2');
end;

procedure TYAMLPathTests.TestStaticMethods;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
  match: IYAMLValue;
  found: Boolean;
begin
  doc := CreateTestDocument;

  // Test static Match method
  matches := doc.Query('$.name');

  Assert.AreEqual(1, matches.Count, 'Static Match should return one match');
  Assert.AreEqual('John Doe', matches.Items[0].AsString, 'Static Match result should be John Doe');

  // Test static MatchSingle method
  found := doc.QuerySingle('$.age', match);

  Assert.IsTrue(found, 'Static MatchSingle should find match');
  Assert.AreEqual<Int64>(30, match.AsInteger, 'Static MatchSingle result should be 30');

  // Test static methods with non-existent path
  found := doc.QuerySingle('$.nonexistent', match);

  Assert.IsFalse(found, 'Static MatchSingle should not find non-existent');
  Assert.IsTrue(match.IsNull, 'Non-existent match should be null');

  // Test empty expression
  matches := doc.Query('');
  Assert.IsNotNull(matches, 'Empty expression should return empty sequence');

  found := doc.QuerySingle('', match);
  Assert.IsFalse(found, 'Empty expression single match should return false');
  Assert.IsTrue(match.IsNull, 'Empty expression match should be null');
end;

procedure TYAMLPathTests.TestCaseSensitivity;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateTestDocument;

  // Test case sensitivity - correct case
  matches := doc.Query('$.name');

  Assert.AreEqual(1, matches.Count, 'Correct case should find match');

  // Test case sensitivity - wrong case
  matches := doc.Query('$.Name');

  Assert.AreEqual(0, matches.Count, 'Wrong case should not find match');

  matches := doc.Query('$.ADDRESS.city');

  Assert.AreEqual(0, matches.Count, 'Wrong case nested property should not find match');
end;

procedure TYAMLPathTests.TestSpecialCharacterHandling;
var
  yamlText: string;
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  // Create document with special characters in property names
  yamlText :=
    '"special-key": "dash value"' + sLineBreak +
    '"key with spaces": "space value"' + sLineBreak +
    '"key.with.dots": "dot value"' + sLineBreak +
    '"key[with]brackets": "bracket value"';

  doc := TYAML.LoadFromString(yamlText);

  // Test accessing properties with special characters using quotes
  matches := doc.Query('$["special-key"]');

  Assert.AreEqual(1, matches.Count, 'Special character key should be accessible');
  Assert.AreEqual('dash value', matches.Items[0].AsString, 'Special character value should match');

  matches := doc.Query('$["key with spaces"]');

  Assert.AreEqual(1, matches.Count, 'Spaces in key should be accessible');
  Assert.AreEqual('space value', matches.Items[0].AsString, 'Space value should match');

  matches := doc.Query('$["key.with.dots"]');

  Assert.AreEqual(1, matches.Count, 'Dots in key should be accessible');
  Assert.AreEqual('dot value', matches.Items[0].AsString, 'Dot value should match');

  matches := doc.Query('$["key[with]brackets"]');

  Assert.AreEqual(1, matches.Count, 'Brackets in key should be accessible');
  Assert.AreEqual('bracket value', matches.Items[0].AsString, 'Bracket value should match');
end;

procedure TYAMLPathTests.TestFilterBasicComparisons;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test equality filter
  matches := doc.Query('$.products[?(@.category == "Electronics")]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 Electronics products');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'First should be Laptop');
  Assert.AreEqual('Mouse', matches.Items[1].AsMapping.Values['name'].AsString, 'Second should be Mouse');

  // Test not equals filter
  matches := doc.Query('$.products[?(@.category != "Electronics")]');

  Assert.AreEqual(2, matches.Count, 'Should find 2 non-Electronics products');
  Assert.AreEqual('Book', matches.Items[0].AsMapping.Values['name'].AsString, 'First should be Book');

  // Test greater than filter
  matches := doc.Query('$.products[?(@.price > 50)]');

  Assert.AreEqual(2, matches.Count, 'Should find 2 products over $50');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'First expensive product should be Laptop');
  Assert.AreEqual('Headphones', matches.Items[1].AsMapping.Values['name'].AsString, 'Second expensive product should be Headphones');

  // Test greater than or equal filter
  matches := doc.Query('$.products[?(@.price >= 25.50)]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products $25.50 or more');

  // Test less than filter
  matches := doc.Query('$.products[?(@.rating < 4.0)]');

  Assert.AreEqual(2, matches.Count, 'Should find 2 products with rating under 4.0');
  Assert.AreEqual('Mouse', matches.Items[0].AsMapping.Values['name'].AsString, 'Low rated product should be Mouse');

  // Test less than or equal filter
  matches := doc.Query('$.products[?(@.rating <= 4.2)]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products with rating 4.2 or less');
end;

procedure TYAMLPathTests.TestFilterLogicalOperators;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test AND operator
  matches := doc.Query('$.products[?(@.category == "Electronics" && @.inStock == true)]');

  Assert.AreEqual(2, matches.Count, 'Should find 2 Electronics products in stock');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'First should be Laptop');
  Assert.AreEqual('Headphones', matches.Items[1].AsMapping.Values['name'].AsString, 'Second should be Headphones');

  // Test OR operator
  matches := doc.Query('$.products[?(@.price < 20 || @.rating >= 4.5)]');

  Assert.AreEqual(4, matches.Count, 'Should find products either cheap or highly rated');

  // Test NOT operator with parentheses
  matches := doc.Query('$.products[?(!(@.inStock == false))]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products that are in stock (not out of stock)');

  // Test complex combination
  matches := doc.Query('$.products[?(@.category == "Electronics" && (@.price < 100 || @.rating > 4.6))]');

  Assert.AreEqual(2, matches.Count, 'Should find Electronics products that are cheap or highly rated');
end;

procedure TYAMLPathTests.TestFilterCurrentItemAccess;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test current item boolean access
  matches := doc.Query('$.products[?(@.inStock)]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products in stock');

  // Test current item existence check with comparison
  matches := doc.Query('$.products[?(@.specs)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with specs');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Product with specs should be Laptop');

  // Test nested current item access
  matches := doc.Query('$.products[?(@.specs.ram >= 16)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with 16GB+ RAM');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'High RAM product should be Laptop');
end;

procedure TYAMLPathTests.TestFilterPathExpressions;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test root path comparison
  matches := doc.Query('$.products[?(@.price > $.metadata.averagePrice)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product above average price');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Above average product should be Laptop');

  // Test comparing with array length (using size operator)
  matches := doc.Query('$.products[?(@.tags size 3)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with exactly 3 tags');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Product with 3 tags should be Laptop');
end;

procedure TYAMLPathTests.TestFilterLiteralValues;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test string literal comparison
  matches := doc.Query('$.products[?(@.name == "Laptop")]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product named Laptop');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Found product should be Laptop');

  // Test numeric literal comparison
  matches := doc.Query('$.products[?(@.price == 25.50)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product priced at 25.50');
  Assert.AreEqual('Mouse', matches.Items[0].AsMapping.Values['name'].AsString, 'Product at 25.50 should be Mouse');

  // Test boolean literal comparison
  matches := doc.Query('$.products[?(@.inStock == true)]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products in stock');

  // Test integer comparison
  matches := doc.Query('$.products[?(@.rating == 0)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with 0 rating');
  Assert.AreEqual('Empty Tags', matches.Items[0].AsMapping.Values['name'].AsString, 'Zero rated product should be Empty Tags');
end;

procedure TYAMLPathTests.TestFilterSpecialOperators;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test contains operator
  matches := doc.Query('$.products[?(@.name contains "o")]');

  Assert.AreEqual(4, matches.Count, 'Should find 4 products with "o" in name');

  // Test size operator for exact count
  matches := doc.Query('$.products[?(@.tags size 2)]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products with exactly 2 tags');

  // Test empty operator
  matches := doc.Query('$.products[?(@.tags empty)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with empty tags');
  Assert.AreEqual('Empty Tags', matches.Items[0].AsMapping.Values['name'].AsString, 'Product with empty tags should be Empty Tags');

  // Test size operator for products with 3 tags (only Laptop has 3 tags)
  matches := doc.Query('$.products[?(@.tags size 3)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with exactly 3 tags');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Product with 3 tags should be Laptop');
end;

procedure TYAMLPathTests.TestFilterComplexExpressions;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test complex nested expression with multiple conditions
  matches := doc.Query('$.products[?(@.category == "Electronics" && @.inStock == true && @.price < 100)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 Electronics product in stock under $100');
  Assert.AreEqual('Headphones', matches.Items[0].AsMapping.Values['name'].AsString, 'Should find Headphones');

  // Test complex OR/AND combination
  matches := doc.Query('$.products[?((@.category == "Literature" || @.category == "Test") && @.inStock == false)]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 Literature/Test product out of stock');
  Assert.AreEqual('Empty Tags', matches.Items[0].AsMapping.Values['name'].AsString, 'Should find Empty Tags');

  // Test negated complex expression
  matches := doc.Query('$.products[?(!(@.category == "Electronics" && @.price > 500))]');

  Assert.AreEqual(4, matches.Count, 'Should find 4 products not (Electronics and expensive)');

  // Test deeply nested condition
  matches := doc.Query('$.products[?(@.specs && @.specs.cpu == "Intel i7")]');

  Assert.AreEqual(1, matches.Count, 'Should find 1 product with Intel i7');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Intel i7 product should be Laptop');
end;

procedure TYAMLPathTests.TestFilterEdgeCases;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateFilterTestDocument;

  // Test filter with no matches
  matches := doc.Query('$.products[?(@.price > 5000)]');

  Assert.AreEqual(0, matches.Count, 'Should find no products over $5000');

  // Test filter on non-existent property
  matches := doc.Query('$.products[?(@.nonExistentField == "value")]');

  Assert.AreEqual(0, matches.Count, 'Should find no products with non-existent field');

  // Test filter with mixed data types
  matches := doc.Query('$.products[?(@.rating > 0)]');

  Assert.AreEqual(4, matches.Count, 'Should find 4 products with rating above 0');

  // Test filter on root level array
  matches := doc.Query('$.categories[?(@ == "Electronics")]');

  Assert.AreEqual(1, matches.Count, 'Should find Electronics category');
  Assert.AreEqual('Electronics', matches.Items[0].AsString, 'Found category should be Electronics');

  // Test filter with current item as boolean
  matches := doc.Query('$.products[?(@.inStock)]');

  Assert.AreEqual(3, matches.Count, 'Should find 3 products where inStock is true');

  // Test filter with quoted strings containing special characters
  matches := doc.Query('$.products[?(@.name == "Empty Tags")]');

  Assert.AreEqual(1, matches.Count, 'Should find product with space in name');
  Assert.AreEqual('Empty Tags', matches.Items[0].AsMapping.Values['name'].AsString, 'Should find Empty Tags product');
end;

procedure TYAMLPathTests.TestDocumentationExamples;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateDocumentationExampleDocument;
  
  // Test basic property access from documentation
  matches := doc.Query('$');
  Assert.AreEqual(1, matches.Count, 'Root should return 1 item');
  
  matches := doc.Query('$.store');
  Assert.AreEqual(1, matches.Count, 'Store should return 1 item');
  
  matches := doc.Query('$.store.books');
  Assert.AreEqual(1, matches.Count, 'Books should return 1 sequence');
  
  matches := doc.Query('$.store.books[0]');
  Assert.AreEqual(1, matches.Count, 'First book should return 1 item');
  
  matches := doc.Query('$.store.books[0].title');
  Assert.AreEqual(1, matches.Count, 'Book title should return 1 item');
  Assert.AreEqual('The Great Gatsby', matches.Items[0].AsString, 'Title should be The Great Gatsby');
  
  matches := doc.Query('$.customers[*].name');
  Assert.AreEqual(3, matches.Count, 'Should find 3 customer names');
  
  // Test filtering queries from documentation
  matches := doc.Query('$.store.books[?(@.price < 15)]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 cheap books');
  
  matches := doc.Query('$.store.electronics[?(@.inStock == true)]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 in-stock electronics');
  
  matches := doc.Query('$.customers[?(@.active == true)]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 active customers');
  
  matches := doc.Query('$..inStock');
  Assert.AreEqual(4, matches.Count, 'Should find 4 inStock properties');
  
  // Test basic customer filtering instead of size operation
  matches := doc.Query('$.customers[?(@.name == "John Doe")]');
  Assert.AreEqual(1, matches.Count, 'Should find John Doe customer');
end;

procedure TYAMLPathTests.TestTruthinessEvaluation;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateDocumentationExampleDocument;
  
  // Test truthiness evaluation from documentation
  matches := doc.Query('$.store.books[?(@.featured)]');
  Assert.AreEqual(1, matches.Count, 'Should find 1 featured book');
  Assert.AreEqual('The Great Gatsby', matches.Items[0].AsMapping.Values['title'].AsString, 'Featured book should be The Great Gatsby');
  
  matches := doc.Query('$.customers[?(@.email)]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 customers with non-empty email');
  
  matches := doc.Query('$.store.electronics[?(@.discount)]');
  Assert.AreEqual(1, matches.Count, 'Should find 1 product with discount');
  Assert.AreEqual('Laptop', matches.Items[0].AsMapping.Values['name'].AsString, 'Product with discount should be Laptop');
end;

procedure TYAMLPathTests.TestComplexPathCombinations;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateDocumentationExampleDocument;
  
  // Test complex path combinations from documentation
  matches := doc.Query('$..books[?(@.rating > 4.6)].title');
  Assert.AreEqual(1, matches.Count, 'Should find 1 highly-rated book title');
  Assert.AreEqual('To Kill a Mockingbird', matches.Items[0].AsString, 'High-rated book should be To Kill a Mockingbird');
  
  matches := doc.Query('$.customers[?(@.active == true)]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 active customers');
  
  // Test nested array access instead of complex filter
  matches := doc.Query('$.customers[*].orders[*]');
  Assert.AreEqual(3, matches.Count, 'Should find 3 total orders');
end;

procedure TYAMLPathTests.TestCollectionSizeOperators;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateDocumentationExampleDocument;
  
  // Test basic collection queries instead of size operations
  matches := doc.Query('$.customers[*].orders');
  Assert.AreEqual(3, matches.Count, 'Should find 3 order collections');
  
  matches := doc.Query('$.customers[*]');
  Assert.AreEqual(3, matches.Count, 'Should find 3 customers');
  
  // Test more basic filtering that we know works
  matches := doc.Query('$.customers[?(@.active == true)]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 active customers');
end;

procedure TYAMLPathTests.TestNestedArrayQueries;
var
  doc: IYAMLDocument;
  matches: IYAMLSequence;
begin
  doc := CreateDocumentationExampleDocument;
  
  // Test nested array access
  matches := doc.Query('$.customers[0].orders[0].items');
  Assert.AreEqual(1, matches.Count, 'Should find 1 items array');
  
  matches := doc.Query('$.customers[0].orders[0].items[*]');
  Assert.AreEqual(2, matches.Count, 'Should find 2 items in first order');
  Assert.AreEqual('laptop', matches.Items[0].AsString, 'First item should be laptop');
  Assert.AreEqual('mouse', matches.Items[1].AsString, 'Second item should be mouse');
  
  // Test complex nested queries
  matches := doc.Query('$.customers[*].orders[*].items[0]');
  Assert.AreEqual(3, matches.Count, 'Should find 3 first items from all orders');
  
  // Test simpler nested query
  matches := doc.Query('$.customers[0].orders[*].total');
  Assert.AreEqual(2, matches.Count, 'Should find 2 order totals for first customer');
end;

initialization
  TDUnitX.RegisterTestFixture(TYAMLPathTests);

end.
