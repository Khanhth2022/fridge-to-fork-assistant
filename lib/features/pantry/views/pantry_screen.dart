import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../view_models/pantry_view_model.dart';
import '../models/pantry_item_model.dart';
import 'add_item_bottom_sheet.dart';

class PantryScreen extends StatelessWidget {
		static String formatDate(DateTime date) {
			return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
		}
	const PantryScreen({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return ChangeNotifierProvider<PantryViewModel>(
			create: (_) {
				final vm = PantryViewModel();
				vm.initMockData();
				return vm;
			},
			child: Consumer<PantryViewModel>(
				builder: (context, viewModel, child) {
					return Scaffold(
						appBar: AppBar(
							title: const Text('Kho Nguyên Liệu'),
						),
						body: viewModel.items.isEmpty
								? Center(
										child: Column(
											mainAxisAlignment: MainAxisAlignment.center,
											children: [
												Icon(Icons.kitchen, size: 64, color: Colors.grey[400]),
												const SizedBox(height: 16),
												Text(
													'Chưa có nguyên liệu',
													style: TextStyle(fontSize: 18, color: Colors.grey[600]),
												),
											],
										),
									)
								: ListView.separated(
										padding: const EdgeInsets.all(16),
										itemCount: viewModel.items.length,
										separatorBuilder: (context, index) => const SizedBox(height: 12),
										itemBuilder: (context, index) {
											final item = viewModel.items[index];
											return Card(
												shape: RoundedRectangleBorder(
													borderRadius: BorderRadius.circular(16),
												),
												elevation: 3,
												child: Padding(
													padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
													child: Row(
														children: [
															Expanded(
																child: Column(
																	crossAxisAlignment: CrossAxisAlignment.start,
																	children: [
																		Text(
																			item.name,
																			style: const TextStyle(
																				fontWeight: FontWeight.bold,
																				fontSize: 18,
																			),
																		),
																		const SizedBox(height: 4),
																		Text(
																			'Số lượng: ${item.quantity} ${item.unit}',
																			style: const TextStyle(
																				fontSize: 14,
																				color: Colors.black54,
																			),
																		),
																		const SizedBox(height: 2),
																		Text(
																			  'Ngày mua: ${PantryScreen.formatDate(item.purchaseDate)}',
																			style: const TextStyle(fontSize: 13, color: Colors.black45),
																		),
																		Text(
																			  'HSD: ${PantryScreen.formatDate(item.expiryDate)}',
																			style: const TextStyle(fontSize: 13, color: Colors.black45),
																		),
																	],
																),
															),
															IconButton(
																icon: const Icon(Icons.edit),
																color: Colors.blueAccent,
																tooltip: 'Cập nhật',
																onPressed: () async {
																	final updated = await showModalBottomSheet<PantryItemModel>(
																		context: context,
																		isScrollControlled: true,
																		shape: const RoundedRectangleBorder(
																			borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
																		),
																		builder: (sheetContext) => AddItemBottomSheet(
																			initialItem: item,
																			onAdd: (updatedItem) {
																				Navigator.pop(sheetContext, updatedItem);
																			},
																		),
																	);
																	if (updated != null) {
																		viewModel.updateItem(index, updated);
																	}
																},
															),
															IconButton(
																icon: const Icon(Icons.delete),
																color: Colors.red,
																tooltip: 'Xóa',
																onPressed: () {
																	viewModel.deleteItem(index);
																},
															),
														],
													),
												),
											);
										},
									),
						floatingActionButton: FloatingActionButton(
							backgroundColor: Color(0xFF9575CD), // tím nhạt hơn
							onPressed: () async {
								await showModalBottomSheet(
									context: context,
									isScrollControlled: true,
									shape: const RoundedRectangleBorder(
										borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
									),
									builder: (sheetContext) => AddItemBottomSheet(
										onAdd: (item) {
											viewModel.addItem(item);
										},
									),
								);
							},
							child: const Icon(Icons.add),
						),
					);
				},
			),
		);
	}
}
