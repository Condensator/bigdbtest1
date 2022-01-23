SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[CPURestructures](
	[Id] [bigint] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) COLLATE Latin1_General_CI_AS NOT NULL,
	[AtInception] [bit] NOT NULL,
	[EffectiveDate] [date] NOT NULL,
	[Status] [nvarchar](9) COLLATE Latin1_General_CI_AS NOT NULL,
	[OldCPUFinanceId] [bigint] NOT NULL,
	[CPUFinanceId] [bigint] NOT NULL,
	[CPUContractId] [bigint] NOT NULL,
	[ContractAmendmentReasonCodeId] [bigint] NULL,
	[CreatedById] [bigint] NOT NULL,
	[CreatedTime] [datetimeoffset](7) NOT NULL,
	[UpdatedById] [bigint] NULL,
	[UpdatedTime] [datetimeoffset](7) NULL,
	[RowVersion] [timestamp] NOT NULL,
	[Description] [nvarchar](200) COLLATE Latin1_General_CI_AS NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF)
)

GO
ALTER TABLE [dbo].[CPURestructures]  WITH CHECK ADD  CONSTRAINT [ECPURestructure_ContractAmendmentReasonCode] FOREIGN KEY([ContractAmendmentReasonCodeId])
REFERENCES [dbo].[ContractAmendmentReasonCodes] ([Id])
GO
ALTER TABLE [dbo].[CPURestructures] CHECK CONSTRAINT [ECPURestructure_ContractAmendmentReasonCode]
GO
ALTER TABLE [dbo].[CPURestructures]  WITH CHECK ADD  CONSTRAINT [ECPURestructure_CPUContract] FOREIGN KEY([CPUContractId])
REFERENCES [dbo].[CPUContracts] ([Id])
GO
ALTER TABLE [dbo].[CPURestructures] CHECK CONSTRAINT [ECPURestructure_CPUContract]
GO
ALTER TABLE [dbo].[CPURestructures]  WITH CHECK ADD  CONSTRAINT [ECPURestructure_CPUFinance] FOREIGN KEY([CPUFinanceId])
REFERENCES [dbo].[CPUFinances] ([Id])
GO
ALTER TABLE [dbo].[CPURestructures] CHECK CONSTRAINT [ECPURestructure_CPUFinance]
GO
ALTER TABLE [dbo].[CPURestructures]  WITH CHECK ADD  CONSTRAINT [ECPURestructure_OldCPUFinance] FOREIGN KEY([OldCPUFinanceId])
REFERENCES [dbo].[CPUFinances] ([Id])
GO
ALTER TABLE [dbo].[CPURestructures] CHECK CONSTRAINT [ECPURestructure_OldCPUFinance]
GO
