# CanoniCAI

##### Table of Contents  
- [What is a competency](#what-is-a-competency)
- [What are the components to make up a competency](#what-is-the-components-to-make-up-a-competency)
- [Build the skeleton for your new competency](#step-1)
- [How to write custom business logics for canonicai](#step-2)
- [How to edit or create responses from each state](#step-3)
- [How to test competency](#step-4)

# What is a competency
A competency is a specialized piece of an AI model program that comes together to solve a problem.

# What are the components to make up a competency
They are several components that makes up the competency and they are as follows:
* ai model
* states
* business logic
* response

#  Step 1: Build the skeleton for your new competency

This step involves the following jac files:
- fixtures.jac
- nodes.jac
- globals.jac

Navigate to ```fixtures.jac``` file, we will be adding states to the graph.
\
We will be creating a state called **check_order** for demo purposes, this will be an extension to the KFC bot. The code we will be adding is 
```state_check_order = spawn node::state(name="check_order");``` into the file. What this does it spawns a node to the graph.

```
graph conv_graph {
    has anchor conv_root;
       spawn {
        state_check_order = spawn node::state(name="check_order");    
       }
```

\
Next, we will be adding this state to the global state. What this does is allow us to connect other states to this in the future, incase if we want the conversation to go back to this state anytime in the future. You will have to go to the ``globals.jac`` file to make the state global.
\
Navigate to the ```globals.jac``` file and add this to the file 

ADD: ``` global check_order_label = "check order"; ```

```
global soc_label = "greetings";
global check_order_label = "check order"; 
global eoc_label = "bye";
global order_label = "order";
global yes_label = "confirmation";
global no_label = "denial";
```

Now we can proceed to the next step. Navigate back to the ```fixture.jac``` file
\
Add: ``` [state_check_order, global.check_order_label] ```

``` 
spawn {
    global_states = [
            [state_check_order, global.check_order_label],
            [state_eoc, global.eoc_label],
            [state_order, global.order_label]
        ];
}
```

\
We will go forward and connect this state to the conversation state, which is the root/main state of the entire application. Because previously we just only created a state but we did not connect it to the root.

ADD: ```conv_root -[transition(intent_label = global.check_order_label)]-> state_check_order;```

``` 
 spawn { 
     conv_root -[transition(intent_label = global.check_order_label)]-> state_check_order;
 }
```

# Step 2: How to write custom business logics for canoniCAI
\
In the ```nodes.jac``` file, this is where the business logic and the responses for each states resides.
\
Navigate to ```nodes.jac``` file, we will be editing or adding to existing node abilities from the states

In this section, we will be editing the state node only. 

For this example we will be using the **[item]** slot for the business logic and we will use this slot to put into our response for the **check order** state. We will also just add a default item just for this small application, So lets start off adding these:

ADD: ``` visitor.dialogue_context["item"] =  '3pc chicken combo';```

```
node state {
    can business_logic { 
         if (!visitor.hoping) {
            // here.name is the title of the state so when we hit that state it runs the code
             if (here.name == "check_order") { 
                 visitor.dialogue_context["item"] = '3pc chicken combo';
             }
         }
    }
}
```
# Step 3: How to edit or create responses from each state
\
In the next section we will focus on creating a response for this competency called **check order**.
\
Navigate to the node ability **gen_response**, this is where it hosts all the responses for each state and using the existing slot from the application, we will add it to the response. So when we query to the application it will give us this exact response, once it classifies correctly.

ADD: ``` visitor.answer = "In your cart you have ordered " + visitor.dialogue_context["item"]; ```

``` 
    can gen_response {
        if (!visitor.hoping) {
            if (here.name == "check_order") {
                visitor.answer = visitor.answer = "In your cart you have ordered " + visitor.dialogue_context["item"];
            }
        }
    }
```

This is how you build a simple competency called check order to canonicai. Hope you guys enjoy this section.

# Step 4: How to test competency
In this section we will be testing the competency to see whether it work or not.

They are genuinely two ways to test this application
* writing test in a ```test.jac``` file
* manually test the application through console or frontend

Let's start with testing manually using the console.
The steps are as follows:
* run jaseci console: ``` jsctl -m ```
* load all the actions required: ``` actions load module [module] ```
* builing the application using:  ``` jac build main.jac ```
* registering the sentinel: ``` sentinel register -set_active true -mode ir main.jir ```
* delete any graph if exists: ``` graph delete active:graph ```
* create the graph: ``` graph create -set_active true ```
* run init walker: ``` walker init ```
* testing the application by running talker: ``` walker talker -ctx "{\"question\": \"can you check what I have ordered so far.\"}" ```

Let's continue with the other method of testing which involves writing a test.

First we will have to navigate to the ```test.jac file```.
\
In this example we will create a simple test that tests the greeting competency and check if it returns a response with the correct user.

``` 
test "test response in greetings"
with graph::empty by walker::init {
    cai_root = *(global.cai_root);
        # Reset user
        spawn cai_root walker::update_user;
        new_dialogue = true;
        
        spawn cai_root walker::talker(
            question="can you check what I have ordered so far.",
            start_new_dialogue=new_dialogue
        );
        
        res = std.get_report();
        assert (res[-1]["response"] == "In your cart you have ordered 3pc chicken combo");
}
```