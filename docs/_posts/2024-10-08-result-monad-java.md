---
layout: post
title:  "Writing the `Result` Monad from Scratch in Java"
tags: java monad functional-programming
image: /assets/result-monad-java.png
---

![Writing the `Result` Monad from Scratch in Java](/assets/result-monad-java.png)

### Writing the `Result` Monad from Scratch in Java

In this article, we will walk through the process of creating a `Result` monad in Java. The `Result` class is a utility designed to encapsulate the result of an operation that can either succeed or fail. It holds either a value of type `V` or an exception indicating an error. This class is useful for handling operations that can either succeed or fail, providing a clear and functional way to manage success and error states.

#### 1. Defining the `Result` Class

First, we define the `Result` class with two fields: `value` and `error`. These fields will hold the successful result and the exception, respectively.

```java
package com.hogemann.monad;

public class Result<V> {

    private final V value;
    private final Exception error;

    private Result(V value, Exception error) {
        this.value = value;
        this.error = error;
    }
}
```

#### 2. Adding Static Methods

Next, we add static methods to create instances of the `Result` class. These methods act as unit functions, which wrap a value or an error into the `Result` context.

- `ok(V value)`: Creates a `Result` instance representing a successful operation.
- `error(Exception error)`: Creates a `Result` instance representing a failed operation.
- `empty()`: Creates an empty `Result` instance with no value or error.

```java
public static <V> Result<V> ok(V value) {
    return new Result<>(value, null);
}

public static <V> Result<V> error(Exception error) {
    return new Result<>(null, error);
}

public static <V> Result<V> empty() {
    return new Result<>(null, null);
}
```

#### 3. Adding Instance Methods

We add instance methods to retrieve the value or error, and to check the state of the `Result`.

- `get()`: Returns the value if the operation was successful.
- `error()`: Returns the exception if the operation failed.
- `isOk()`: Checks if the operation was successful.
- `isEmpty()`: Checks if the result is empty.

```java
public V get() {
    return this.value;
}

public Exception error() {
    return this.error;
}

public boolean isOk() {
    return this.error == null && this.value != null;
}

public boolean isEmpty() {
    return this.value == null && this.error == null;
}
```

#### 4. Adding Monad Operations

To make the `Result` class a monad, we add the `map` and `flatMap` methods. These methods allow for chaining operations while maintaining the context.

- `map(Function<V,U> mapper)`: Transforms the value using the provided function if the operation was successful.
- `flatMap(Function<V,Result<U>> mapper)`: Transforms the value into another `Result` using the provided function if the operation was successful.

```java
public <U> Result<U> map(Function<V, U> mapper) {
    if (isOk()) {
        return ok(mapper.apply(value));
    } else {
        return error(error);
    }
}

public <U> Result<U> flatMap(Function<V, Result<U>> mapper) {
    if (isOk()) {
        return mapper.apply(value);
    } else {
        return error(error);
    }
}
```

#### 5. Adding Utility Methods

Finally, we add a utility method to execute appropriate actions based on whether the operation was successful or not.

- `ifOkOrElse(Consumer<V> consumer, Consumer<Exception> errorConsumer)`: Executes the appropriate consumer based on whether the operation was successful or not.

```java
public void ifOkOrElse(Consumer<V> consumer, Consumer<Exception> errorConsumer) {
    if (isOk()) {
        consumer.accept(value);
    } else {
        errorConsumer.accept(error);
    }
}
```

#### Complete `Result` Class

Here is the complete `Result` class:

```java
package com.hogemann.monad;

import java.util.function.Consumer;
import java.util.function.Function;

public class Result<V> {

    private final V value;
    private final Exception error;

    private Result(V value, Exception error) {
        this.value = value;
        this.error = error;
    }

    public static <V> Result<V> ok(V value) {
        return new Result<>(value, null);
    }

    public static <V> Result<V> error(Exception error) {
        return new Result<>(null, error);
    }

    public static <V> Result<V> empty() {
        return new Result<>(null, null);
    }

    public V get() {
        return this.value;
    }

    public Exception error() {
        return this.error;
    }

    public boolean isOk() {
        return this.error == null && this.value != null;
    }

    public boolean isEmpty() {
        return this.value == null && this.error == null;
    }

    public <U> Result<U> map(Function<V, U> mapper) {
        if (isOk()) {
            return ok(mapper.apply(value));
        } else {
            return error(error);
        }
    }

    public <U> Result<U> flatMap(Function<V, Result<U>> mapper) {
        if (isOk()) {
            return mapper.apply(value);
        } else {
            return error(error);
        }
    }

    public void ifOkOrElse(Consumer<V> consumer, Consumer<Exception> errorConsumer) {
        if (isOk()) {
            consumer.accept(value);
        } else {
            errorConsumer.accept(error);
        }
    }
}
```

### Usage Examples

To demonstrate how to use the `Result` monad, let's look at some practical examples.

#### Example 1: Handling a Successful Operation

In this example, we simulate a successful operation that returns a `Result` containing a value.

```java
public class Example {
    public static void main(String[] args) {
        Result<String> successResult = Result.ok("Operation successful");

        successResult.ifOkOrElse(
            value -> System.out.println("Success: " + value),
            error -> System.err.println("Error: " + error.getMessage())
        );
    }
}
```

Output:
```
Success: Operation successful
```

#### Example 2: Handling a Failed Operation

Here, we simulate a failed operation that returns a `Result` containing an error.

```java
public class Example {
    public static void main(String[] args) {
        Result<String> errorResult = Result.error(new Exception("Operation failed"));

        errorResult.ifOkOrElse(
            value -> System.out.println("Success: " + value),
            error -> System.err.println("Error: " + error.getMessage())
        );
    }
}
```

Output:
```
Error: Operation failed
```

#### Example 3: Chaining Operations with `map`

This example demonstrates how to transform the value inside a `Result` using the `map` method.

```java
public class Example {
    public static void main(String[] args) {
        Result<Integer> initialResult = Result.ok(5);

        Result<Integer> transformedResult = initialResult.map(value -> value * 2);

        transformedResult.ifOkOrElse(
            value -> System.out.println("Transformed Value: " + value),
            error -> System.err.println("Error: " + error.getMessage())
        );
    }
}
```

Output:
```
Transformed Value: 10
```

#### Example 4: Chaining Operations with `flatMap`

In this example, we use the `flatMap` method to chain operations that return `Result` instances.

```java
public class Example {
    public static void main(String[] args) {
        Result<Integer> initialResult = Result.ok(5);

        Result<Integer> finalResult = initialResult.flatMap(value -> Result.ok(value * 2));

        finalResult.ifOkOrElse(
            value -> System.out.println("Final Value: " + value),
            error -> System.err.println("Error: " + error.getMessage())
        );
    }
}
```

Output:
```
Final Value: 10
```

These examples illustrate how the `Result` monad can be used to handle operations that may succeed or fail, and how to chain operations in a functional style.