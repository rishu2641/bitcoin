defmodule Bitcoin do
use Supervisor

  def main(no_of_users,no_of_transactions) do
    #datapoint = "Number of users: #{no_of_users} and number of transactions : #{no_of_transactions}"
    users = user_list(no_of_users)
    miners = miners_list()
    children = miners ++ users
    {:ok, parent_pid} = Supervisor.start_link(children, strategy: :one_for_one)

    [user_map, miner_map] = make_id_map(%{}, %{}, Supervisor.which_children(parent_pid))
    setmap(user_map,miner_map,no_of_transactions)

    start_mining(miner_map)
    blockchain = initial_blockchain(user_map,miner_map)

    initial = :os.system_time(:millisecond)
    datapoint = ""
    datapoint = intervals(miner_map,user_map,datapoint,initial)
    
    listener(user_map, miner_map, [], blockchain, no_of_transactions,datapoint,initial,initial)
  end
  def transaction_updates([t|ts],user_map,datapoint) do
    GenServer.cast(Map.get(user_map,t.sender),{:decrement,t.amount}) 
    senderw = GenServer.call(Map.get(user_map,t.sender),{:get})
    GenServer.cast(Map.get(user_map,t.reciever),{:add,t.amount})
    recieverw = GenServer.call(Map.get(user_map,t.reciever),{:get}) 
    IO.puts "Transaction successful"
    IO.puts "user #{t.sender} sent #{t.amount} and has #{senderw} BTS balance"
    IO.puts "user #{t.reciever} recieved #{t.amount} and has #{recieverw} BTS balance"   
    transaction_updates(ts,user_map,datapoint)
  end

  def transaction_updates([],_user_map,datapoint) do
    datapoint
  end

  def intervals(miner_map,user_map,datapoint,initial) do
    datapoint = datapoint<>"#"<>"#{inspect :os.system_time(:millisecond) - initial}-"
    datapoint = datapoint_miner(Enum.to_list(miner_map),datapoint)
    datapoint = datapoint_user(Enum.to_list(user_map),datapoint)
    datapoint
  end


  def listener(user_map,miner_map, pending, blockchain,no_of_transactions,datapoint,prev,start) do
    receive do
      {:push, pend} -> 
          pending = pending ++ [pend]
          listener(user_map,miner_map,pending,blockchain,no_of_transactions,datapoint,prev,start)             
        # code
      {:fetch,id} ->
          GenServer.cast(id,{:update_tran,pending})
          listener(user_map,miner_map,pending,blockchain,no_of_transactions,datapoint,prev,start)
      {:create_block, block, _miner} ->
        [blockchain,pending,datapoint,prev] = 
        if check(block.data,pending) do
          GenServer.call(Map.get(miner_map,block.miner_num),{:add,5})
          #datapoint = datapoint <> ";" <> "Miner #{miner} got 5 DOSCoins"
          transaction_updates(block.data,user_map,datapoint)

          pending = 
            Enum.reject(pending, fn pen_tr ->
              Enum.any?(block.data, fn tr->
                tr.id == pen_tr.id
              end)
            end) 
          blockchain = blockchain ++ [block]
          Enum.each(user_map, fn{_,pid}->
            GenServer.cast(pid,{:update,blockchain})
          end)
          Enum.each(miner_map, fn{_,pid}->
            GenServer.cast(pid,{:update,blockchain})
          end) 
          cur = curr_time = :os.system_time(:millisecond)
          [prev,datapoint] = 
          if( cur - prev >= 5) do
            [start,intervals(miner_map,user_map,datapoint,start)]
          else 
            [prev,datapoint]
          end
          [blockchain,pending,datapoint,prev]
        else
          [blockchain,pending,datapoint,prev]  
        end
        if length(blockchain)<(no_of_transactions/5)+1 do
          listener(user_map,miner_map,pending,blockchain,no_of_transactions,datapoint,prev,start)
        else
        #datapoint = datapoint_miner(Enum.to_list(miner_map),datapoint)
        #datapoint = datapoint_user(Enum.to_list(user_map),datapoint)
        datapoint = intervals(miner_map,user_map,datapoint,start)
        IO.puts "all transactions completed"
        datapoint
        end
    end
  end

  def datapoint_miner([{miner,minerPID}|miner_map],datapoint) do
    a = GenServer.call(minerPID,{:get})
    datapoint = datapoint <> ";" <> "#{a}"
    datapoint_miner(miner_map,datapoint)
  end

  def datapoint_miner([],datapoint) do
    datapoint
  end

  def datapoint_user([{user,userPID}|user_map],datapoint) do
    a = GenServer.call(userPID,{:get})
    datapoint = datapoint <> ";" <> "#{a}"
    datapoint_user(user_map,datapoint)
  end

  def datapoint_user([],datapoint) do
    datapoint
  end

  def initial_blockchain(user_map,miner_map) do
    block = %{}
    block = Map.put(block, :block_num, 0)
    transaction = Map.put(%{}, :id, 0)
    transaction = Map.put(transaction, :sender, 0)
    transaction = Map.put(transaction, :reciever, 0)
    transaction = Map.put(transaction, :amount, 100000)
    block = Map.put(block, :data, [transaction])
    prev_hash = "0000000000000000000000000000000000000000000000000000000000000000"
    block = Map.put(block, :prev, prev_hash)
    string = "0;100000;0;0;0;0000000000000000000000000000000000000000000000000000000000000000"
    [random, hash] = Helper.gen_zero_string(string,0)
    block = Map.put(block, :random, random)
    block = Map.put(block, :hash, hash)
    blockchain = [block]

    Enum.each user_map,  fn {_user_num, user_pid} ->
      GenServer.cast(user_pid, {:update, blockchain})
    end

    Enum.each miner_map,  fn {_miner_num, miner_pid} ->
      GenServer.cast(miner_pid, {:update, blockchain})
    end

    blockchain    
  end

  def setmap(user_map,miner_map,no_of_transactions) do
    Enum.each  user_map,  fn {_user_num, user_pid} ->
      GenServer.call(user_pid, {:set_maps, user_map, miner_map})
    end

    Enum.each  miner_map,  fn {_miner_num, miner_pid} ->
      GenServer.call(miner_pid, {:set_maps, user_map, miner_map})
    end

    start_transaction(user_map,1,no_of_transactions)
    
  end

  def start_mining(miner_map) do
    Enum.each  miner_map,  fn {_miner_num, miner_pid}  ->
      GenServer.cast(miner_pid, {:mine})
    end

  end

  def check([t | ts], pending) do
    if length(ts) == 0 do
      true
    else
      i = Enum.find_index(pending, fn pend ->
        t.id == pend.id
      end)
      i != nil and check(ts, pending)
    end
  end

  def start_transaction(user_map, curr,no_of_transactions)  do
    if curr<=no_of_transactions do
      [{sen,_},{rec,_}] = Enum.take_random(user_map,2) 
    
      GenServer.cast(Map.get(user_map,sen),{:transaction ,rec,2, "#{inspect(curr)}. #{inspect(sen-10)} sends 2 BTC to #{inspect(rec-10)}" })
      start_transaction(user_map,curr+1,no_of_transactions)
    end
  end


  def miners_list do
    create_miners(1,[])
  end
  def user_list(num) do
    num = 10+num
    create_user(11,num,[])
  end

  def create_miners(curr,list) do
    cond do
      curr <= 10 ->
        [%{
          id: curr,
          start: {Miner, :start_link, [%{:id => curr, :user_map => %{}, :miner_num => curr, :amount => 0, :miner_map => %{}, :blockchain => [], :pending => [], :main_pid => self()}]}
        }] ++ create_miners(curr+1,list)
      true ->
        list  
    end
  end

  def create_user(curr,num,list) do
    cond do
      curr <= num ->           
          [%{
          id: curr,
          start: {User, :start_link, [%{:id => curr, :user_num => curr, :amount => 50, :user_map => %{}, :miner_map => %{}, :blockchain => [], :main_pid => self()}]}
          }] ++ create_user(curr+1,num,list)
      true ->
          list  
    end
  end 
  def make_id_map(user_map, miner_map, [node_obj | node_objs]) do
    {_, node_pid, _, _} = node_obj
    node_id = GenServer.call(node_pid, {:id})
    [user_map, miner_map] =
      if(node_id <= 10) do
        [user_map, Map.put(miner_map, node_id, node_pid)]
      else
        [Map.put(user_map, node_id, node_pid), miner_map]
      end
    make_id_map(user_map, miner_map, node_objs)
  end

  def make_id_map(user_map, miner_map, []) do
    [user_map, miner_map]
  end
  def init(args) do
      {:ok, args}
  end
  def start(_,_) do
    [users, number_transaction] = System.argv()
    Bitcoin.main(String.to_integer(users),String.to_integer(number_transaction))    
  end

end
