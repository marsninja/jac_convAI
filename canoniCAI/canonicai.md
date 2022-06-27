## Getting Started CanoniCAI

##### Clone CanonCAI repo using: https://github.com/marsninja/jac_convAI

- Registering the sentinel by using this command: 
``` sentinel register -set_active true -mode ir main.jir ```

- Then create the graph by using this command:
``` graph create -set_active true ```

- Then initialize the entire application by using:
``` walker run init ``` 



## Explanation of Walkers in CanoniCAI

- **talker**: This is the main walker to interact with the conversational AI. It takes in a question from the user, which then hops from state to state and triggers various node abilities to apply NLU to the question, process some custom logic and then generates an appropriate response.

- **init**: This walker loads the AI models, generates the graph, loads modules and links certain nodes from state to state.

- **train**: These walkers teach the AI model from an existing dataset to learn to do a specific task.

- **set_pretrained_model**: Allows you to interchange what pretrained model you want to use. If you want to use distilbert, tinybert etc.

- **save_model**: Allows you to save the current state of the model you have trained for later use.

- **infer**:  This is where you validate the model by passing a query to see how it’s performing.

- **read**: This walker takes in a source url, scraps the website and then summarizes it to populate the faq state so it can teach anyone of what it has read from the website.

- **forget**: This walker unlearns everything that is in the faq state.

- **maintainer**: Keeps track of the user and its dialogue context alongside with the last conversational state. 

- **update_user**: updates the user. 


## Graph Architecture 

#### There are 4 architectures of the graph.

- User Management
- Conversational States
- Faq Architecture
- AI Model Management


#### The User Management
This is actually straightforward, this state allows us to create and manage users in the entire application alongside with storing the last conversational state of each user.

#### Conversational States
This is where the user query goes to get processed and returned back to the user.

#### Faq Architecture
This state intakes a link from the user which is then read to scrape data from the website into a summarized fashion inorder to be stored as a faq. Which can be later accessed through conversation from a user.

#### AI Model Management

It’s a centralized area for all types of AI models that does specific functions such as NER, Classification, etc. Which can be accessed by the conversational states to perform certain actions.




## How are they connected?

 The first architecture we have to take into consideration is the AI model management state. This is where we map out the types of questions a user may ask alongside with the user intent. We also have to ask ourselves if there are entities that we have to capture in a conversation, like for example where is the location, name, amount of apples in the user question and from there we begin to build out the model before we could build any logic on top of that to connect the application. After the AI model management then we have to move on to the conversational state where we will focus on what we will do with the user intent and the entities extracted from it and from there generate a specific response where applicable. The faq architecture is like a cherry on top of the conversation AI state, how this feature works we first have to feed a website link to the conversational AI and it will take out the appropriate information from the site and maps a summarization form of it which will be fed into the faq state for later processing. We can then ask questions based on the link provided and the model will give you the best answer from what it has learned from the site. The user management state stores all of the user contextual information along with the last conversation dialogue. Now you should be able to understand how they are all connected in a generalized fashion.


## What node actions each state has and how are they triggered by the walkers?

#### State Node

- **Listen**: This node action is responsible for saving results to the walker context. It performs the NLU to analyze the question.
- **Plan**: Based on the NLU result, this decides which state the walker should go next.
- **Take**: Allows the walker to travel to the destination state
- **Think**: The walker is now at the state corresponding to the question asked by the user and this is where State-specific logic is done through ::business_logic
- **Speak**: Construct a response to return to the user
- **Cleanup**: Save any context you wish to retain for the future conversation turns for example it saves the last thing you spoke to the AI and it also is responsible for Post-response wrap-up.




#### FAQ State Node

- **Seek_answer**: based on all the faq nodes that is saved in the graph it will choose the best one that it closest to the original question
- **Init_answer_states**: Based on a file of faq answers it will create nodes in the graph with the answers and its embeddings.
- **Read_url**: read the website and then returns a summarized version of it in which each important sentence will be created as a node on the faq state.
- **Clean_answer_db**: Delete all faq answer state nodes

#### Faq Answer State

- **Speak**: Construct a response to return to the user


#### User State

- **Start_conv**: It collects the user context and starts to save the last conversation state
- **Update_with_conv**: Updates the user context everytime maintainer walker gets called.
init_user : it collects all the user data from the api

#### User Directory State

- **Init_users**: maps the correct user based on the user id and if it's a new user it creates that user.

#### AI Model State

- **Load_model**: load an ai model that was already trained
- **Train_model**: teaches an ai model
- **Save_model**: save the existing model
- **Set_pretrained_model**: switch between models that was already created and saved
- **Infer**: test out the model

