defmodule User do
    use GenServer
    def start_link(args) do
        {private_key, public_key} = :crypto.generate_key(:ecdh, :secp256k1)
        args = Map.put(args, :private_key, private_key)
        args = Map.put(args, :public_key, public_key)
        #IO.puts " #{args.user_num-10} number user created"
        GenServer.start_link(__MODULE__, args)
    end
    def handle_call({:id},_from,state) do
        {:reply,state.id,state}
    end

    def handle_call({:print},_from,state) do
        IO.puts "user #{state.id-10} has #{state.amount} BTS"
        {:reply,:ok ,state}
    end    

    def handle_call({:set_maps, user_map, miner_map}, _from, state) do
        state = Map.put(state, :user_map, user_map)
        state = Map.put(state, :miner_map, miner_map)
        {:reply, :ok, state}
    end

    def handle_call({:get},_from,state) do
        {:reply,state.amount,state}
    end    


    def handle_cast({:transaction,reciever,amount,transact_id},state) do
        transact = Map.put(%{}, :id, transact_id)
        transact = Map.put(transact, :sender, state.user_num)
        transact = Map.put(transact, :reciever, reciever)
        transact = Map.put(transact, :amount, amount)
        check = transact.amount == 2 
        state = 
        if(check) do
            Process.send(state.main_pid, {:push, transact}, [])
            state
           
        else
            state
        end
        {:noreply, state}

    end
 



    def handle_cast({:add,amount},state) do
        state = Map.put(state, :amount, state.amount + amount)
        {:noreply, state}
    end  
    def handle_cast({:decrement,amount},state) do
        state = Map.put(state, :amount, state.amount - amount)
        {:noreply, state}
    end    
    def handle_cast({:update,block},state) do
        state = Map.put(state,:blockchain,block)
        {:noreply,state}
    end
    

    def init(args) do
        {:ok,args}
    end
end