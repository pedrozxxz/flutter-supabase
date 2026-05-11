import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ldbbybrfxnpxnonaqrbo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxkYmJ5YnJmeG5weG5vbmFxcmJvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0NzAzMDUsImV4cCI6MjA5NDA0NjMwNX0.wtoeT3a_ZY5qel2LgvBda2atmY1wA6Tx4tkOtTG1Iek',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Inventário de Produtos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const InventarioPagina(),
    );
  }
}

class InventarioPagina extends StatefulWidget {
  const InventarioPagina({super.key});

  @override
  State<InventarioPagina> createState() => _InventarioPaginaState();
}

class _InventarioPaginaState extends State<InventarioPagina> {
  final _nomeController = TextEditingController();
  final _quantidadeController = TextEditingController();
  final _precoController = TextEditingController();
  final _supabase = Supabase.instance.client;
  
  List<Map<String, dynamic>> _produtos = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarProdutos();
  }

  // READ - Carregar produtos do banco
  Future<void> _carregarProdutos() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await _supabase
          .from('produtos')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        _produtos = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarMensagem('Erro ao carregar produtos: $e');
    }
  }

  // CREATE - Inserir novo produto
  Future<void> _salvarProduto() async {
    if (_nomeController.text.isEmpty) {
      _mostrarMensagem('Por favor, preencha o nome do produto');
      return;
    }

    final nome = _nomeController.text;
    final quantidade = int.tryParse(_quantidadeController.text) ?? 0;
    final preco = double.tryParse(_precoController.text) ?? 0.0;

    setState(() {
      _isLoading = true;
    });

    try {
      await _supabase.from('produtos').insert({
        'nome': nome,
        'quantidade': quantidade,
        'preco': preco,
      });
      
      // Limpar os campos
      _nomeController.clear();
      _quantidadeController.clear();
      _precoController.clear();
      
      // Recarregar a lista
      await _carregarProdutos();
      
      _mostrarMensagem('Produto salvo com sucesso!');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _mostrarMensagem('Erro ao salvar produto: $e');
    }
  }

  // UPDATE - Incrementar quantidade em +1
  Future<void> _incrementarQuantidade(Map<String, dynamic> produto) async {
    final novaQuantidade = (produto['quantidade'] ?? 0) + 1;
    
    try {
      await _supabase
          .from('produtos')
          .update({'quantidade': novaQuantidade})
          .eq('id', produto['id']);
      
      await _carregarProdutos();
      _mostrarMensagem('Quantidade atualizada!');
    } catch (e) {
      _mostrarMensagem('Erro ao atualizar quantidade: $e');
    }
  }

  // DELETE - Remover produto
  Future<void> _deletarProduto(Map<String, dynamic> produto) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text('Deseja realmente excluir o produto "${produto['nome']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _supabase
            .from('produtos')
            .delete()
            .eq('id', produto['id']);
        
        await _carregarProdutos();
        _mostrarMensagem('Produto excluído com sucesso!');
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        _mostrarMensagem('Erro ao excluir produto: $e');
      }
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // Método para formatar preço
  String _formatarPreco(double preco) {
    return 'R\$ ${preco.toStringAsFixed(2)}';
  }

  // Método para definir a cor do preço baseado no valor (Bônus)
  Color _getPrecoColor(double preco) {
    return preco > 100 ? Colors.green : Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventário de Produtos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Formulário de cadastro
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nomeController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Produto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.production_quantity_limits),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantidadeController,
                            decoration: const InputDecoration(
                              labelText: 'Quantidade',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _precoController,
                            decoration: const InputDecoration(
                              labelText: 'Preço (R\$)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.attach_money), // Ícone corrigido
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _salvarProduto,
                        icon: const Icon(Icons.save),
                        label: const Text('Salvar Produto'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Lista de produtos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produtos Cadastrados:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _isLoading && _produtos.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _produtos.isEmpty
                            ? const Center(
                                child: Text('Nenhum produto cadastrado'),
                              )
                            : ListView.builder(
                                itemCount: _produtos.length,
                                itemBuilder: (context, index) {
                                  final produto = _produtos[index];
                                  final preco = (produto['preco'] ?? 0.0).toDouble();
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.deepPurple,
                                        child: Text(
                                          '${produto['quantidade'] ?? 0}',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ),
                                      title: Text(
                                        produto['nome'] ?? 'Sem nome',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('Quantidade: ${produto['quantidade'] ?? 0}'),
                                          Text(
                                            _formatarPreco(preco),
                                            style: TextStyle(
                                              color: _getPrecoColor(preco),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.add_circle, color: Colors.green),
                                            onPressed: () => _incrementarQuantidade(produto),
                                            tooltip: 'Incrementar quantidade',
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            onPressed: () => _deletarProduto(produto),
                                            tooltip: 'Excluir produto',
                                          ),
                                        ],
                                      ),
                                      onTap: () => _incrementarQuantidade(produto),
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _quantidadeController.dispose();
    _precoController.dispose();
    super.dispose();
  }
}