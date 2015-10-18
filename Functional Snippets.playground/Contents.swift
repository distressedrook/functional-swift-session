//: Playground - noun: a place where people can play

import Foundation

//Swift methods are not composable
//We should do everything to promote composition
//Curried functions are highly composable


let xs = Array(1...100)

func square(x : Int) -> Int {
    return x * x
}

func incr(x: Int) -> Int {
    return x + 1
}

func isPrime(p:Int) -> Bool {
    if p <= 1 { return false }
    if p <= 3 { return true }
    
    for i in 2...Int(sqrtf(Float(p))) {
        if p % i == 0 { return false }
    }
    return true
}


infix operator <|> {associativity left}

//Takes a value of type `A` and a closure that accepts an arguemnt of type `A` and returns the result which is of type `B`. The first argument is passed as an argument of the closure and will get you the results.

func <|> <A,B> (x:A, f:A -> B) -> B {
    return f(x)
}

//Takes in two functions as arguments. One that accepts an arugment of type `A` and spits out a result of type `B`; and the other that accepts the argument of type `B` and spits out an argument of type `C`. It spits out a function that accepts an argument of type `A` and spits out an argument of type `C`. Basically, this overload returns a chain of two methods.
func <|> <A,B,C> (f: A -> B, g : B -> C) -> (A -> C) {
    //We have to return a closure that accepts an argument of type `A` and return something of type `C`
    return { a in
        return g(f(a))
    }
}

2 * 22 <|> incr <|> square


xs.map(square)
xs.filter(isPrime)
xs.reduce(0,combine: +)

//Mimics the system's map function
func map<A,B>(f: A -> B)  -> [A] -> [B] {
    return { xs in
        return xs.map(f)
    }
}


//map returns a function that takes xs as an argument and performs square and increment on each element in that order
xs <|> map(square <|> incr)
xs <|> map(square) <|> map(incr)



func filter<A>(f: A -> Bool) -> [A] -> [A] {
    return { xs in
        return xs.filter(f)
        
    }
}

xs <|> filter(isPrime) <|>  map(incr <|> square)


//The problem here is that we would have to iterate through the array of one to hundred at least twice. Even with the optimization as shown above. Of course this is much better than...

xs <|> filter(isPrime) <|> map(incr) <|> map(square)

//... where you iterate thrice

/*
This is where the concept of "Transducers" and "Reducers" come in. 

1. A Reducer on a type A is a function of the form (C,A) -> C for some type C.
2. A Transducer is a function that takes a reducer on A and returns a reducer on B. This could look something like:

((C,A) -> C) -> ((C,B) -> C)
3. The whole `map`, `filter`, `take` and other fundamental functions can be rewritten using the map function. 
4.
*/


func mapFromReduce <A,B> (f:A -> B) -> [A] -> [B] {
    return { a in
        return a.reduce([]) { accum, x in
            return accum + [f(x)]
        }
        
    }
}

func filterFromReduce <A> (f : A -> Bool) -> [A] -> [A] {
    return { a in
        return a.reduce([]) {accum, x in
            return f(x) ? accum + [x] : accum
        }
        
    }
}

func takeFromReduce <A> (n:Int) -> [A] -> [A] {
    return { a in
        return a.reduce([]) { accum, x in
            a.count < n ? accum + [x] : accum
            
        }
        
    }
}



func squaringReducer <C> (reducer: (C,Int) -> C) -> ((C,Int) -> C) {
    return { accum,x in
        return reducer(accum, x * x)
    }
}

//This will add all the elements in the array, using system's built in `reduce` function
xs.reduce(0) { accum,result in
    return accum + result
}

//This will add all the elements in the array using the default + reducer. Note that + reducer has the signature: (Int, Int) -> Int.
xs.reduce(0,combine: +)

//We pass the `+` reducer to the squaringReducer. It will return a reducer
xs.reduce(0,combine: squaringReducer(+))



//This method takes in a function as an argument and returns a transducer from A to B.
func mapping < A, B, C> (f: A -> B) -> ( ( (C,B) -> C) -> ( (C,A) -> C) ) {
    return { reducer in
        return { accum, x in
            return reducer(accum,f(x))
        }
    }
}

func filtering< A,C>(predicate:A -> Bool) -> ( (C,A) -> C)  -> ( (C,A) -> C) {
    return { reducer in
        return { accum, x in
            return predicate(x) ? reducer(accum,x) : accum
            
        }
        
    }
}




//Let us see how we can redo our original problem of squareing, incrementing by one and finding the prime numbers all the elements in such an array. 

/*
1. We need a reduce. Because we have transducers that map reducers to reducers.
2. We thrown in xs because that's the array I want to map to.
3. And the initial value will be an empty array. 
4. I cannot just do `reduce(xs,[],mapping(square)), because mapping is a transducer. We can't feed it into a reduce. We can only feed reducers to reduce.

5. TRANSDUCERS TAKE REDUCERS AND SPIT OUT REDUCERS.

*/

//1. This is a reducer on type [A]. It took a arguments of type [A] and A and reduced it to [A]. Remember Reducer == C,A -> C. In this context, [A] = C and A = A
func append<A>(array:[A],x:A) -> [A] {
    return array + [x]
}


//2. Since append is a reducer, the reduce function took the initial empty array, and tried to reduce the array with the given reducer.


xs.reduce([], combine: append <|> filtering(isPrime) <|> mapping(square <|> incr))

//Atomic, stateless, highly composable pieces of functions. The combination of which provides predictable and testable code.

