defmodule Miner do
    use GenServer

    def start_link(args) do
        {private_key, public_key} = :crypto.generate_key(:ecdh, :secp256k1)
        args = Map.put(args, :private_key, private_key)
        args = Map.put(args, :public_key, public_key)
        GenServer.start_link(__MODULE__,args)
    end

    def to_string([t | ts], string) do
        if length(ts) == 0 do
            string
        else
            to_string(ts, Integer.to_string(t.amount) <> t.id <> Integer.to_string(t.reciever-10) <> Integer.to_string(t.sender-10))
        end
    end
    


    def handle_cast({:mine}, state) do
        Process.send(state.main_pid,{:fetch,self()},[])
        {:noreply, state}
    end


    def handle_cast({:update,block},state) do
        state = Map.put(state,:blockchain,block)
        {:noreply,state}
    end

    def handle_cast({:update_tran,pending},state) do
        state = Map.put(state, :pending, pending)
        if length(pending) >= 5 do
            list = Enum.take(pending, 5)
            block = %{}
            block_num = length(state.blockchain)
            block = Map.put(block, :block_num, block_num)
            block = Map.put(block, :miner_num, state.miner_num)
            block = Map.put(block, :data, list)
            prev_hash = Enum.at(state.blockchain, 0).hash
            block = Map.put(block, :prev, prev_hash)
            hash_string = Integer.to_string(block_num) <> ";" <> Integer.to_string(state.miner_num) <> ";" <> to_string(list, "") <> ";" <> prev_hash
            [random,hash] = Helper.gen_zero_string(hash_string,0)
            block = Map.put(block, :hash, hash)
            block = Map.put(block, :random, random)
            Process.send(state.main_pid, {:create_block, block, state.miner_num}, [])
        end
        GenServer.cast(self(), {:mine})
        {:noreply, state}        
    end    

    def handle_call({:set_maps, user_map, miner_map}, _from, state) do
        state = Map.put(state, :user_map, user_map)
        state = Map.put(state, :miner_map, miner_map)
        # IO.inspect state
        {:reply, :ok, state}
    end

    def handle_call({:add,amount},_from,state) do
        state = Map.put(state,:amount,state.amount+amount)
        {:reply,:ok,state}
    end

    def handle_call({:id},_from,state) do
        {:reply,state.id,state}
    end

    def handle_call({:get},_from,state) do
        {:reply,state.amount,state}
    end    

    def handle_call({:print},_from,state) do
        IO.puts "miner #{state.id} has #{state.amount} BTS"
        {:reply,:ok,state}
    end

    



    def init(args) do
        {:ok,args}
    end
end