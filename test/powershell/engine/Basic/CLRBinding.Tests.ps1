# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

Describe ".NET Method Binding Tests" -tags CI {
    BeforeAll {
        Add-Type -TypeDefinition @'
using System;

namespace CLRBindingTests;

public class TestClass
{
    public static string SingleOverload(string value) => value;

    public static string OverloadWithSameNameDifferentCase(string value, string Value) => $"{value}{Value}";

    public static string MultipleArguments(string value1, string value2 = "default1", string value3 = "default2") => $"{value1}{value2}{value3}";

    public static int OverloadByType(string stringValue) => 1;
    public static int OverloadByType(int intValue) => 2;

    public static string OverloadWithDefaults(string value1, int value2, string default1 = "foo", string default2 = null) => $"{value1}-{value2}-{default1}-{default2}";

    public static string Params(string value, params string[] remainder) => $"{value}-" + string.Join("-", remainder);

    public static string ParamsWithDefault(string value, string defaultArg = "foo", params string[] remainder) => $"{value}-{defaultArg}-" + string.Join("-", remainder);
}
'@
    }

    It "Fails with single overload with mismatch name" {
        $err = { [CLRBindingTests.TestClass]::SingleOverload(other: 'foo') } | Should -Throw -PassThru
        [string]$err | Should -Be 'Cannot find an overload for "SingleOverload" and the argument count: "1".'
    }

    It "Fails with single overload with mismatch case sensitive name" {
        $err = { [CLRBindingTests.TestClass]::SingleOverload(Value: 'foo') } | Should -Throw -PassThru
        [string]$err | Should -Be 'Cannot find an overload for "SingleOverload" and the argument count: "1".'
    }

    It "Uses single overload with correct name" {
        [CLRBindingTests.TestClass]::SingleOverload(value: 'foo') | Should -Be foo
    }

    It "Fails to call method with too little arguments" {
        $err = { [CLRBindingTests.TestClass]::SingleOverload() } | Should -Throw -PassThru
        [string]$err | Should -Be 'Cannot find an overload for "SingleOverload" and the argument count: "0".'
    }

    It "Fails to call method with too many arguments" {
        $err = { [CLRBindingTests.TestClass]::SingleOverload('value', 'other') } | Should -Throw -PassThru
        [string]$err | Should -Be 'Cannot find an overload for "SingleOverload" and the argument count: "2".'
    }

    It "Uses overload with arg name that differs by case" {
        [CLRBindingTests.TestClass]::OverloadWithSameNameDifferentCase(value: 'foo', Value: 'bar') | Should -Be foobar
    }

    It "Calls method with arguments in different positional order" {
        [CLRBindingTests.TestClass]::MultipleArguments(value2: 'bar', value3: 'test', value1: 'foo') | Should -Be foobartest
    }

    It "Calls method with arguments with positional and named order" {
        [CLRBindingTests.TestClass]::MultipleArguments('foo', value3: 'test', value2: 'bar') | Should -Be foobartest
    }

    It "Fails to find overload when positional argument was already used" {
        $err = { [CLRBindingTests.TestClass]::MultipleArguments('foo', value1: 'bar') } | Should -Throw -PassThru
        [string]$err | Should -Be 'Cannot find an overload for "MultipleArguments" and the argument count: "2".'
    }

    It "Calls method with default overload by type" {
        [CLRBindingTests.TestClass]::OverloadByType('1') | Should -Be 1
    }

    It "Calls method with overriden overload by name" {
        [CLRBindingTests.TestClass]::OverloadByType(intValue: '1') | Should -Be 2
    }

    It "Calls method with named default normal" {
        [CLRBindingTests.TestClass]::OverloadWithDefaults('v1', 2, default1: 'bar') | Should -Be 'v1-2-bar-'
    }

    It "Calls method with named default out of order" {
        [CLRBindingTests.TestClass]::OverloadWithDefaults('v1', 2, default2: 'other') | Should -Be 'v1-2-foo-other'
    }

    It "Calls params with no value" {
        [CLRBindingTests.TestClass]::Params("first") | Should -Be first-
    }

    It "Calls params with single value" {
        [CLRBindingTests.TestClass]::Params("first", "second") | Should -Be first-second
    }

    It "Calls params with multiple values" {
        [CLRBindingTests.TestClass]::Params("first", "second", "third") | Should -Be first-second-third
    }

    It "Calls params with array value" {
        [CLRBindingTests.TestClass]::Params("first", [string[]]@("second", "third")) | Should -Be first-second-third
    }

    It "Calls params with single named value" {
        [CLRBindingTests.TestClass]::Params("first", remainder: "second") | Should -Be first-second
    }

    It "Calls params with array named value" {
        [CLRBindingTests.TestClass]::Params("first", remainder: [string[]]@("second", "third")) | Should -Be first-second-third
    }

    It "Calls params with named arguments out of order" {
        [CLRBindingTests.TestClass]::Params(remainder: "second", value: "first") | Should -Be first-second
    }

    It "Calls params with default value and no params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first") | Should -Be first-foo-
    }

    It "Calls params with default value and single params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", remainder: "second") | Should -Be first-foo-second
    }

    It "Calls params with default value and array params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", remainder: [string[]]@("second", "third")) | Should -Be first-foo-second-third
    }

    It "Calls params with default value set and no params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "bar") | Should -Be first-bar-
    }

    It "Calls params with default value set and single params through position" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "bar", "second") | Should -Be first-bar-second
    }

    It "Calls params with default value set and single params through name" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "bar", remainder: "second") | Should -Be first-bar-second
    }

    It "Calls params with default value set and array params through name" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "bar", remainder: [string[]]@("second", "third")) | Should -Be first-bar-second-third
    }

    It "Calls params with default value set and array params through array position" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "bar", [string[]]@("second", "third")) | Should -Be first-bar-second-third
    }

    It "Calls params with default value set and array params through multiple position" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "bar", "second", "third") | Should -Be first-bar-second-third
    }

    It "Calls params with default value through named arg no params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", defaultArg: "bar") | Should -Be first-bar-
    }

    It "Calls params with default value through named arg single params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", defaultArg: "bar", remainder: "second") | Should -Be first-bar-second
    }

    It "Calls params with default value through named arg array params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", defaultArg: "bar", remainder: [string[]]@("second", "third")) | Should -Be first-bar-second-third
    }

    It "Calls params with default value through named arg after single params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "second", defaultArg: "bar") | Should -Be first-bar-second-third
    }

    It "Calls params with default value through named arg after named single params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", remainder: "second", defaultArg: "bar") | Should -Be first-bar-second
    }

    It "Calls params with default value through named arg after multiple params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", "second", "third", defaultArg: "bar") | Should -Be first-bar-second-third
    }

    It "Calls params with default value through named arg after array params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", [string[]]@("second", "third"), defaultArg: "bar") | Should -Be first-bar-second-third
    }

    It "Calls params with default value through named arg after named array params" {
        [CLRBindingTests.TestClass]::ParamsWithDefault("first", remainder: [string[]]@("second", "third"), defaultArg: "bar") | Should -Be first-bar-second-third
    }
}
