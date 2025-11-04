# ?ーゲット定義
makeTarget_mdascollector64 = build_mdascollector64
makeTarget_64 = build_64
installTarget_mdascollector64 = install_mdascollector64
installTarget_64 = install_64


# 疑似?ーゲット（?ーゲットなしでmake実行したときはmdas_collectorのビルドとする）
.PHONY: build
build: $(makeTarget_mdascollector64)

# 関連モジュールのビルドを行う?ーゲット（mdas_collector/64bit）
module:
# bit指定がされない場合は何もしない
ifeq ($(BITS), )
	@echo "module build error. please specify BITS."
else # ifeq ($(BITS), )
#	tcp_client, tcp_serverビルド（機種依存なし、bit依存あり）
	@cd Common/tcp_client; make -s build_$(BITS)
	@cd Common/tcp_server; make -s build_$(BITS)

# RepoUtil, Repository, RepoMainビルド（機種依存あり、bit依存あり）
ifeq ($(TARGET_MODEL), )
#	?ーゲットモデルが指定されない状態でmake呼び出しされた場合、MachineModel配下の全機種ビルド
	@for f in $(shell ls -d ../MachineModel/*/); \
	do \
		d=`basename $${f}`; \
		pushd Repository/app/RepoUtil; make MODEL_TYPE="$${d}" -s build_$(BITS); popd; \
		pushd ../MachineModel/$${d}/CppCode/Repository; make MODEL_TYPE="$${d}" BITS=$(BITS) -s build; popd; \
	done
ifeq ($(BITS), 64)
	pushd Repository/app/RepoMain; make -s build_$(BITS); popd;
endif # ifeq ($(BITS), 64)

else # ifeq ($(TARGET_MODEL), )
#	?ーゲットモデルが指定された状態でmake呼び出しされた場合は、その機種のみビルド
	pushd Repository/app/RepoUtil; make MODEL_TYPE="${TARGET_MODEL}" -s build_$(BITS); popd;
	pushd ../MachineModel/${TARGET_MODEL}/CppCode/Repository; make MODEL_TYPE="${TARGET_MODEL}" BITS=$(BITS) -s build; popd;
ifeq ($(BITS), 64)
	pushd Repository/app/RepoMain; make -s build_$(BITS); popd;
endif # ifeq ($(BITS), 64)
endif # ifeq ($(TARGET_MODEL), )
endif # ifeq ($(BITS), )

#	FieldTypeCheckerビルド（機種依存なし, bit依存なし）
	@cd FieldTypeChecker; make -s

build_mdascollector64:
	@echo "Build for mdas_collector - build only mdas_collector.exe"
	@make module BITS=mdascollector64
ifeq ($(TARGET_MODEL), )
		@for f in $(shell ls -d ../MachineModel/*/); \
		do \
			d=`basename $${f}`; \
			pushd ../MachineModel/$${d}/CppCode/mdas_collector/RepoAdapter; make MODEL_TYPE="$${d}" -j 7; popd; \
			pushd mdas_collector; make MODEL_TYPE="$${d}"; popd; \
		done
	#	@cd SdExtractor/app; make -s build
else
			pushd ../MachineModel/${TARGET_MODEL}/CppCode/mdas_collector/RepoAdapter; make MODEL_TYPE="${TARGET_MODEL}" -j 7; popd;
			pushd mdas_collector; make MODEL_TYPE="${TARGET_MODEL}"; popd;
endif

build_64:
	@echo "Repository build for 64bit"
	@make module BITS=64
ifeq ($(TARGET_MODEL), )
		@for f in $(shell ls -d ../MachineModel/*/); \
		do \
			d=`basename $${f}`; \
			mv ../MachineModel/$${d}/CppCode/Repository/lib/py_repo_tcp.so ../MachineModel/$${d}/CppCode/Repository/lib/py_repo_tcp_64bit.so;\
		done
else
			mv ../MachineModel/${TARGET_MODEL}/CppCode/Repository/lib/py_repo_tcp.so ../MachineModel/${TARGET_MODEL}/CppCode/Repository/lib/py_repo_tcp_64bit.so;
endif
	@mv Repository/app/RepoMain/esprit_repo_mem Repository/app/RepoMain/esprit_repo_mem_64bit; 
	@cd mdas_adapter; make -s build
	@cd mdas_reque; make -s build

# install?ーゲット
install: $(installTarget_mdascollector64) $(installTarget_64);

# mdas_collector install?ーゲット
# echoしかやっていないが必要か？
install_mdascollector64:
	@echo "    Installing modules in CppCode...(mdas_collector)"
#	@sh install32.sh

# 64bit install?ーゲット
install_64:
	@echo "    Installing modules in CppCode...(64bit)"
	@for f in $(shell ls -d ../MachineModel/*/); \
	do \
		d=`basename $${f}`; \
                rm -rf ${MDAS_ARC_DIR}/mdas_$${d}; \
                mkdir -p ${MDAS_ARC_DIR}/mdas_$${d}/lib; \
                mkdir -p ${MDAS_ARC_DIR}/mdas_$${d}/bin; \
		cp -f ../MachineModel/$${d}/CppCode/Repository/lib/*.so ${MDAS_ARC_DIR}/mdas_$${d}/lib; \
		cp -f ../MachineModel/$${d}/CppCode/Repository/bin/*.so ${MDAS_ARC_DIR}/mdas_$${d}/bin; \
		cp -f ../MachineModel/$${d}/CppCode/mdas_collector/mdas_collector.exe ${MDAS_ARC_DIR}/mdas_$${d}/bin; \
	done
	@mkdir -p ${MDAS_ARC_BIN}
	@mkdir -p ${MDAS_ARC_LIB}
	@cp -f FieldTypeChecker/field_type_checker ${MDAS_ARC_BIN}
	@cp -f mdas_adapter/lib/*.so ${MDAS_ARC_LIB}
	@cp -f mdas_reque/bin/mdas_reque ${MDAS_ARC_BIN}
	@cp -f Repository/app/RepoMain/esprit_repo_mem* ${MDAS_ARC_BIN}
	
clean:
	@cd Common/tcp_client; make -s clean
ifeq ($(TARGET_MODEL), )
	@cd Common/tcp_server; make -s clean
		@for f in $(shell ls -d ../MachineModel/*/); \
		do \
			d=`basename $${f}`; \
			pushd Repository/app/RepoUtil; make MODEL_TYPE="$${d}" -s clean; popd; \
			pushd ../MachineModel/$${d}/CppCode/Repository; make MODEL_TYPE="$${d}" -s clean; popd; \
			pushd Repository/app/RepoMain; make MODEL_TYPE="$${d}" -s clean; popd; \
			pushd ../MachineModel/$${d}/CppCode/mdas_collector/RepoAdapter; make MODEL_TYPE="$${d}" -s clean; popd; \
			pushd mdas_collector; make MODEL_TYPE="$${d}" -s clean; popd; \
		done
else
			pushd Repository/app/RepoUtil; make MODEL_TYPE="${TARGET_MODEL}" -s clean; popd;
			pushd ../MachineModel/${TARGET_MODEL}/CppCode/Repository; make MODEL_TYPE="${TARGET_MODEL}" -s clean; popd;
			pushd Repository/app/RepoMain; make MODEL_TYPE="${TARGET_MODEL}" -s clean; popd;
			pushd ../MachineModel/${TARGET_MODEL}/CppCode/mdas_collector/RepoAdapter; make MODEL_TYPE="${TARGET_MODEL}" -s clean; popd;
			pushd mdas_collector; make MODEL_TYPE="${TARGET_MODEL}" -s clean; popd;
endif
	@cd FieldTypeChecker; make -s clean
	@cd mdas_adapter; make -s clean
	@cd mdas_reque; make -s clean
	@rm -rf *.o *~

