---
layout: post
title:  "Using database functions in JPA Criteria projections"
tags: java jpa
categories: java jpa
image: /assets/jpa-function-criteria-query.png
---

![JPA Function Criteria Query](/assets/jpa-function-criteria-query.png)

JPA and Hibernate are great if you don’t step too much outside the regular mapping-tables-to-objects business, but if you want to do a bit more with your database using the Criteria API, you might find some gotchas.

For example, I was trying to map the following query to a projection, and failing:

```sql
SELECT
    FORMAT(timestamp, ''yyyy-DD-mm'') as day,
    COUNT(value) as count,
    value as value
FROM
    table
GROUP BY
    FORMAT(timestamp, ''yyyy-MM-dd''), value;
The java bit of the projection was like this:

Query query = cb.multiselect(
    cb.function("format", String.class, Table_.timestamp, cb.literal("yyyy-MM-dd"),
    cb.count(Table_.value),
    root. Get(Table_.value),
);
```


But, if you’re targeting MS SQL Server, executing this will trigger an exception looking like the one bellow:

```java
java.lang.NullPointerException at org.hibernate.hql.internal.ast.tree.ConstructorNode.formatMissingContructorExceptionMessage(ConstructorNode.java:192)
```

Not very helpful, but what’s actually happening here is: Hibernate doesn’t know about the FORMAT function in MS SQL Server. So, the way it get to learn about the SQL syntax of a given database is through a dialect class. There are many dialects to choose from when dealing with MS SQL Server, but none has the FORMAT function registered!

How do I know? Well, I looked at the source code… really. I invite you to go ahead and do the same, they’re really simple to understand, they’re here.

So, in the end, the solution was to register the FORMAT by extending the dialect I was using, SQLServer2012Dialect, and register the function myself.

```java
public class ExtendedSQLServerDialect extends SQLServer2012Dialect {
public ExtendedSQLServerDialect() {
        registerFunction(
            "format",   
            new SQLFunctionTemplate(
                StandardBasicTypes.STRING,
                "FORMAT(?1, ?2)"));
    }
}
```

Use it in your application configuration, instead of the one provided Hibernate, and that should solve the problem.